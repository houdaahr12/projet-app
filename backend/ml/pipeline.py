import json
import math
from sqlalchemy import text
from ml.features import VITALS_LABS, features_last
import ml.model_service as model_service

COLS = ", ".join(VITALS_LABS)


def get_param(conn, key, default):
    row = conn.execute(text("SELECT valeur FROM parametres WHERE cle=:k"), {"k": key}).first()
    return float(row[0]) if row else float(default)


def model_version_id(conn) -> int:
    name = model_service.active_name()
    return conn.execute(text("""
        INSERT INTO model_versions (nom, version, algorithme, actif)
        VALUES (:n, '2.0', 'LightGBM + calibration isotonic', TRUE)
        ON CONFLICT (nom, version) DO UPDATE SET actif = TRUE RETURNING id
    """), {"n": name}).scalar()


def _clean(value):
    if value is None:
        return None
    try:
        value = float(value)
    except (TypeError, ValueError):
        return None
    return None if not math.isfinite(value) else value


def insert_measurement(conn, patient_id, heure_icu, values: dict, saisi_par=None) -> int:
    vals = {key: _clean(values.get(key)) for key in VITALS_LABS}
    vals = {key: value for key, value in vals.items() if value is not None}
    # La règle du notebook remplace les valeurs O2Sat hors de [50, 100] par NaN.
    if "o2sat" in vals and not 50 <= vals["o2sat"] <= 100:
        vals.pop("o2sat")
    params = {"patient_id": patient_id, "heure_icu": int(heure_icu), "saisi_par": saisi_par, **vals}
    cols = list(params)
    sql = (
        f"INSERT INTO measurements ({', '.join(cols)}) "
        f"VALUES ({', '.join(':' + col for col in cols)}) RETURNING id"
    )
    return conn.execute(text(sql), params).scalar()


def _previous_risk(conn, patient_id: int, current_hour: int, version_id: int) -> float | None:
    cfg = model_service.thresholds()
    lag = int(cfg.get("rising_lag_hours", 6))
    target_hour = current_hour - lag
    if target_hour < 0:
        return None
    value = conn.execute(text("""
        SELECT pr.score
        FROM predictions pr
        JOIN measurements m ON m.id = pr.measurement_id
        WHERE pr.patient_id = :p AND pr.model_version_id = :v AND m.heure_icu <= :h
        ORDER BY m.heure_icu DESC
        LIMIT 1
    """), {"p": patient_id, "v": version_id, "h": target_hour}).scalar()
    return None if value is None else float(value)


def process_measurement(conn, patient_id, measurement_id, create_alert=True) -> dict:
    if not model_service.is_loaded():
        raise RuntimeError("Modèle notebook non chargé : impossible de créer une prédiction.")

    patient = conn.execute(text(
        "SELECT age, sexe, unit1, unit2, hosp_adm_time FROM patients WHERE id=:i"
    ), {"i": patient_id}).mappings().one()
    rows = conn.execute(text(
        f"SELECT heure_icu, {COLS} FROM measurements WHERE patient_id=:i ORDER BY heure_icu"
    ), {"i": patient_id}).mappings().all()
    X = features_last(rows, dict(patient), model_service.feature_names())
    score, factors = model_service.predict(X)
    current_hour = int(rows[-1]["heure_icu"])
    first_hour = int(rows[0]["heure_icu"])
    active_model_version_id = model_version_id(conn)
    previous = _previous_risk(conn, patient_id, current_hour, active_model_version_id)
    # Le notebook retient un warm-up de 3 heures : aucune alerte pendant cette période.
    warmup_hours = int(model_service.thresholds().get("warmup_hours", 0))
    warmup_active = (current_hour - first_hour) < warmup_hours
    level = "normal" if warmup_active else model_service.classify_level(score, previous)

    prediction_id = conn.execute(text("""
        INSERT INTO predictions (patient_id, measurement_id, model_version_id, score, niveau, facteurs)
        VALUES (:p, :m, :v, :s, :n, CAST(:f AS JSONB)) RETURNING id
    """), {
        "p": patient_id, "m": measurement_id, "v": active_model_version_id,
        "s": round(score, 4), "n": level, "f": json.dumps(factors),
    }).scalar()

    alert_id = None
    if create_alert and level == "alerte":
        alert_id = _maybe_alert(conn, patient_id, prediction_id, score, factors, current_hour)
    return {
        "score": round(score, 4), "niveau": level, "facteurs": factors,
        "alert_id": alert_id, "warmup_actif": warmup_active,
    }


def _maybe_alert(conn, patient_id, prediction_id, score, factors, hour):
    open_alert = conn.execute(text(
        "SELECT 1 FROM alerts WHERE patient_id=:p AND statut IN "
        "('nouvelle','vue','prise_en_charge') LIMIT 1"
    ), {"p": patient_id}).first()
    if open_alert:
        return None

    silence_hours = get_param(conn, "delai_silence_min", 60) / 60
    last_hour = conn.execute(text("""
        SELECT m.heure_icu
        FROM alerts a
        JOIN predictions pr ON pr.id = a.prediction_id
        JOIN measurements m ON m.id = pr.measurement_id
        WHERE a.patient_id=:p
        ORDER BY a.creee_le DESC LIMIT 1
    """), {"p": patient_id}).scalar()
    if last_hour is not None and hour - int(last_hour) < silence_hours:
        return None

    alert_id = conn.execute(text("""
        INSERT INTO alerts (patient_id, prediction_id, score, facteurs)
        VALUES (:p, :pr, :s, CAST(:f AS JSONB)) RETURNING id
    """), {
        "p": patient_id, "pr": prediction_id, "s": round(score, 4), "f": json.dumps(factors),
    }).scalar()
    conn.execute(text("""
        INSERT INTO alert_history (alert_id, user_id, ancien_statut, nouveau_statut, note)
        VALUES (:a, NULL, NULL, 'nouvelle', 'Alerte générée par le modèle du notebook')
    """), {"a": alert_id})
    notify(patient_id, alert_id, score)
    return alert_id


def notify(patient_id, alert_id, score):
    # TODO: intégrer Firebase Cloud Messaging via device_tokens.
    print(f"[ALERTE] patient={patient_id} alerte={alert_id} risque={score:.3f}")
