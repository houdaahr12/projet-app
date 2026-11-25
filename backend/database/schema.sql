-- schema.sql : base Sepsis_db (PostgreSQL)

-- =========================================================
-- 1. UTILISATEURS
-- =========================================================
CREATE TABLE IF NOT EXISTS users (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom                 VARCHAR(100) NOT NULL,
    identifiant         VARCHAR(50)  NOT NULL UNIQUE,      
    email               VARCHAR(150) UNIQUE,
    mot_de_passe_hash   TEXT         NOT NULL,           
    role                VARCHAR(20)  NOT NULL
                        CHECK (role IN ('admin', 'medecin')),
    service             VARCHAR(100),
    sexe                CHAR(1) CHECK (sexe IN ('M', 'F')),
    actif               BOOLEAN      NOT NULL DEFAULT TRUE,
    doit_changer_mdp    BOOLEAN      NOT NULL DEFAULT TRUE,
    cree_par            BIGINT REFERENCES users(id) ON DELETE SET NULL,
    cree_le             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    derniere_connexion  TIMESTAMPTZ
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS sexe CHAR(1) CHECK (sexe IN ('M', 'F'));

-- =========================================================
-- 2. PATIENTS (anonymisés : aucun nom réel)
-- =========================================================
CREATE TABLE IF NOT EXISTS patients (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code_patient        VARCHAR(20) NOT NULL UNIQUE,       -- ex. P-0231
    age                 NUMERIC(4,1) NOT NULL CHECK (age BETWEEN 0 AND 120),
    sexe                CHAR(1) NOT NULL CHECK (sexe IN ('M', 'F')),
    service             VARCHAR(100),
    lit                 VARCHAR(10),
    unit1               SMALLINT CHECK (unit1 IN (0, 1)),
    unit2               SMALLINT CHECK (unit2 IN (0, 1)),
    hosp_adm_time       NUMERIC(8,2),                      
    admis_icu_le        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    statut              VARCHAR(10) NOT NULL DEFAULT 'actif'
                        CHECK (statut IN ('actif', 'sorti')),
    sorti_le            TIMESTAMPTZ,
    source              VARCHAR(12) NOT NULL DEFAULT 'manuel'
                        CHECK (source IN ('manuel', 'simulation')),
    cree_par            BIGINT REFERENCES users(id) ON DELETE SET NULL,
    cree_le             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS patient_events (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id  BIGINT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    user_id     BIGINT REFERENCES users(id) ON DELETE SET NULL,
    type        VARCHAR(30) NOT NULL
                CHECK (type IN ('admission', 'transfert', 'sortie', 'note', 'diagnostic_confirme')),
    details     TEXT,
    cree_le     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_patient_events ON patient_events (patient_id, cree_le DESC);

-- Soignants qui suivent un patient (écran "Mes patients")
CREATE TABLE IF NOT EXISTS patient_soignants (
    patient_id  BIGINT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    user_id     BIGINT NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    affecte_le  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (patient_id, user_id)
);

-- Progression de la simulation (quel patient en est à quelle ligne du jeu de test)
CREATE TABLE IF NOT EXISTS sim_cursor (
    patient_id       BIGINT PRIMARY KEY REFERENCES patients(id) ON DELETE CASCADE,
    source_key       TEXT    NOT NULL,           -- fichier .psv d'origine
    next_idx         INTEGER NOT NULL DEFAULT 0, -- prochaine ligne (heure) à envoyer
    sepsis_onset_idx INTEGER                     -- ligne où SepsisLabel passe à 1 (NULL = pas de sepsis)
);

-- =========================================================
-- 3. MESURES HORAIRES (mêmes variables que PhysioNet 2019)
-- =========================================================
CREATE TABLE IF NOT EXISTS measurements (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id       BIGINT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    heure_icu        INTEGER NOT NULL CHECK (heure_icu >= 0),   -- ICULOS
    mesure_le        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    saisi_par        BIGINT REFERENCES users(id) ON DELETE SET NULL,  -- NULL si simulation

    -- signes vitaux
    hr               NUMERIC(6,2),   -- fréquence cardiaque (bpm)
    o2sat            NUMERIC(5,2) CHECK (o2sat BETWEEN 0 AND 100),
    temp             NUMERIC(4,2),   -- température (°C)
    sbp              NUMERIC(6,2),   -- tension systolique
    map              NUMERIC(6,2),   -- tension moyenne
    dbp              NUMERIC(6,2),   -- tension diastolique
    resp             NUMERIC(5,2),   -- fréquence respiratoire
    etco2            NUMERIC(6,2),

    -- analyses de laboratoire (toutes facultatives)
    baseexcess       NUMERIC(6,2),
    hco3             NUMERIC(6,2),
    fio2             NUMERIC(6,3),   -- peut être en pourcentage (jusqu'à 100) : NUMERIC(5,3) refuserait 100
    ph               NUMERIC(4,2),
    paco2            NUMERIC(6,2),
    sao2             NUMERIC(5,2),
    ast              NUMERIC(8,2),
    bun              NUMERIC(6,2),
    alkalinephos     NUMERIC(8,2),
    calcium          NUMERIC(5,2),   -- total OU ionisé (le prétraitement les sépare)
    chloride         NUMERIC(6,2),
    creatinine       NUMERIC(5,2),
    bilirubin_direct NUMERIC(5,2),
    glucose          NUMERIC(6,2),
    lactate          NUMERIC(5,2),
    magnesium        NUMERIC(5,2),
    phosphate        NUMERIC(5,2),
    potassium        NUMERIC(4,2),
    bilirubin_total  NUMERIC(5,2),
    troponini        NUMERIC(7,3),
    hct              NUMERIC(5,2),
    hgb              NUMERIC(5,2),
    ptt              NUMERIC(6,2),
    wbc              NUMERIC(6,2),
    fibrinogen       NUMERIC(7,2),
    platelets        NUMERIC(7,2),

    UNIQUE (patient_id, heure_icu)    -- une seule mesure par heure et par patient
);

ALTER TABLE measurements ALTER COLUMN fio2 TYPE NUMERIC(6,3);

-- =========================================================
-- 4. MODÈLES ET PRÉDICTIONS
-- =========================================================
CREATE TABLE IF NOT EXISTS model_versions (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom             VARCHAR(50) NOT NULL,              -- ex. xgboost_sepsis
    version         VARCHAR(20) NOT NULL,              -- ex. 1.0
    algorithme      VARCHAR(50),
    chemin_fichier  TEXT,                              -- ex. models/xgb_v1.pkl
    metriques       JSONB,                             -- AUROC, AUPRC, utilité, etc.
    actif           BOOLEAN NOT NULL DEFAULT FALSE,
    cree_le         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (nom, version)
);

CREATE TABLE IF NOT EXISTS predictions (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id        BIGINT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    measurement_id    BIGINT NOT NULL REFERENCES measurements(id) ON DELETE CASCADE,
    model_version_id  BIGINT NOT NULL REFERENCES model_versions(id),
    score             NUMERIC(5,4) NOT NULL CHECK (score BETWEEN 0 AND 1),
    niveau            VARCHAR(15) NOT NULL
                      CHECK (niveau IN ('normal', 'surveillance', 'alerte')),
    facteurs          JSONB,     -- ex. [{"variable":"lactate","impact":0.31}, ...] (SHAP)
    calcule_le        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Une prédiction par (mesure, modèle) : permet de comparer 2 modèles plus tard
ALTER TABLE predictions DROP CONSTRAINT IF EXISTS predictions_measurement_id_key;
CREATE UNIQUE INDEX IF NOT EXISTS uq_pred_mesure_modele ON predictions (measurement_id, model_version_id);

-- =========================================================
-- 5. ALERTES
-- =========================================================
CREATE TABLE IF NOT EXISTS alerts (
    id                      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id              BIGINT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    prediction_id           BIGINT NOT NULL REFERENCES predictions(id) ON DELETE CASCADE,
    score                   NUMERIC(5,4) NOT NULL CHECK (score BETWEEN 0 AND 1),
    facteurs                JSONB,
    statut                  VARCHAR(20) NOT NULL DEFAULT 'nouvelle'
                            CHECK (statut IN ('nouvelle', 'vue', 'prise_en_charge', 'cloturee')),
    creee_le                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    vue_par                 BIGINT REFERENCES users(id) ON DELETE SET NULL,
    vue_le                  TIMESTAMPTZ,
    prise_en_charge_par     BIGINT REFERENCES users(id) ON DELETE SET NULL,
    prise_en_charge_le      TIMESTAMPTZ,
    note                    TEXT,
    cloturee_le             TIMESTAMPTZ
);

-- Une seule alerte ouverte par patient
CREATE UNIQUE INDEX IF NOT EXISTS uq_alerte_ouverte
    ON alerts (patient_id) WHERE statut IN ('nouvelle', 'vue', 'prise_en_charge');

-- Historique détaillé de chaque alerte
CREATE TABLE IF NOT EXISTS alert_history (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    alert_id       BIGINT NOT NULL REFERENCES alerts(id) ON DELETE CASCADE,
    user_id        BIGINT REFERENCES users(id) ON DELETE SET NULL,   -- NULL si c'est le système
    ancien_statut  VARCHAR(20),
    nouveau_statut VARCHAR(20) NOT NULL
                   CHECK (nouveau_statut IN ('nouvelle', 'vue', 'prise_en_charge', 'cloturee')),
    note           TEXT,
    cree_le        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alert_history ON alert_history (alert_id, cree_le);

-- =========================================================
-- 6. NOTIFICATIONS PUSH (Firebase Cloud Messaging)
-- =========================================================
CREATE TABLE IF NOT EXISTS device_tokens (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token        TEXT NOT NULL UNIQUE,
    plateforme   VARCHAR(10) CHECK (plateforme IN ('android', 'ios')),
    cree_le      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
-- 7. PARAMÈTRES ET JOURNAL
-- =========================================================
CREATE TABLE IF NOT EXISTS parametres (
    cle          VARCHAR(50) PRIMARY KEY,
    valeur       TEXT NOT NULL,
    modifie_par  BIGINT REFERENCES users(id) ON DELETE SET NULL,
    modifie_le   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_log (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT REFERENCES users(id) ON DELETE SET NULL,
    action      VARCHAR(50) NOT NULL,          -- ex. connexion, creation_patient, alerte_vue
    entite      VARCHAR(30),                   -- ex. patient, alert, user
    entite_id   BIGINT,
    details     JSONB,
    ip          VARCHAR(45),
    cree_le     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
-- 8. INDEX (pour la rapidité)
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_measurements_patient   ON measurements (patient_id, heure_icu DESC);
CREATE INDEX IF NOT EXISTS idx_predictions_patient    ON predictions  (patient_id, calcule_le DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_statut          ON alerts (statut, creee_le DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_patient         ON alerts (patient_id, creee_le DESC);
CREATE INDEX IF NOT EXISTS idx_patients_statut        ON patients (statut);
CREATE INDEX IF NOT EXISTS idx_audit_user             ON audit_log (user_id, cree_le DESC);

-- =========================================================
-- 9. VUE : dernier risque de chaque patient
-- =========================================================
CREATE OR REPLACE VIEW v_patients_risque AS
SELECT DISTINCT ON (p.id)
       p.id, p.code_patient, p.age, p.sexe, p.lit, p.service, p.statut,
       pr.score, pr.niveau, pr.calcule_le
FROM patients p
LEFT JOIN predictions pr ON pr.patient_id = p.id
ORDER BY p.id, pr.calcule_le DESC;

-- =========================================================
-- 10. DONNÉES DE DÉPART
-- =========================================================
INSERT INTO parametres (cle, valeur) VALUES
    ('seuil_alerte',       '0.35'),
    ('seuil_surveillance', '0.15'),
    ('delai_silence_min',  '60')     -- délai avant une nouvelle alerte pour le même patient
ON CONFLICT (cle) DO NOTHING;