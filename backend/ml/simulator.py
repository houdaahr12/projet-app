"""Rejeu horaire de tous les patients du split TEST du notebook."""
from pathlib import Path
import os
import random
from collections import OrderedDict
import pandas as pd
from sqlalchemy import text
from database import engine
from ml.features import VITALS_LABS
from ml import pipeline

BASE_DIR = Path(__file__).resolve().parents[1]
DATA_DIR_RAW = Path(os.getenv("SIM_DATA_DIR", "sim_data_test"))
DATA_DIR = DATA_DIR_RAW if DATA_DIR_RAW.is_absolute() else BASE_DIR / DATA_DIR_RAW
MANIFEST_PATH = DATA_DIR / "test_patients.csv"
N_PATIENTS = int(os.getenv("SIM_PATIENTS", "8"))
N_SEPSIS = int(os.getenv("SIM_SEPSIS_PATIENTS", "3"))
BED_COUNT = max(1, int(os.getenv("SIM_BED_COUNT", "30")))
CACHE_PATIENTS = max(1, int(os.getenv("SIM_CACHE_PATIENTS", "32")))
PRELOAD = int(os.getenv("SIM_PRELOAD_HOURS", "12"))
PRED_HIST = int(os.getenv("SIM_PRED_HISTORY", "8"))
_rng = random.Random(int(os.getenv("SIM_SEED", "42")))
_index = None
_cache = OrderedDict()


def is_configured() -> bool:
    return MANIFEST_PATH.is_file()


def _read(filename: str) -> pd.DataFrame:
    filename = Path(filename).name  # interdit les chemins fournis par le manifeste
    if filename in _cache:
        _cache.move_to_end(filename)
        return _cache[filename]

    path = DATA_DIR / filename
    if not path.is_file():
        raise FileNotFoundError(f"Fichier de test absent : {path}")
    frame = pd.read_csv(path, sep="|")
    _cache[filename] = frame
    while len(_cache) > CACHE_PATIENTS:
        _cache.popitem(last=False)
    return frame


def _get_index():
    """Charge l'index complet du TEST sans charger tous les PSV en mémoire."""
    global _index
    if _index is not None:
        return _index
    if not MANIFEST_PATH.is_file():
        raise FileNotFoundError(
            f"Manifeste du split TEST absent : {MANIFEST_PATH}. "
            "Exécutez la cellule d'export à la fin du notebook."
        )

    manifest = pd.read_csv(MANIFEST_PATH)
    required = {"patient_id", "hospital", "filename", "is_sepsis", "sepsis_onset_idx", "n_rows"}
    missing_columns = required.difference(manifest.columns)
    if missing_columns:
        raise ValueError(f"Manifeste test_patients.csv incomplet : {sorted(missing_columns)}")
    if manifest.empty:
        raise ValueError("Le manifeste TEST est vide : aucun patient à simuler.")

    entries = []
    missing_files = []
    for row in manifest.to_dict("records"):
        filename = Path(str(row["filename"])).name
        path = DATA_DIR / filename
        if not path.is_file():
            missing_files.append(filename)
            continue

        length = int(row["n_rows"])
        if length <= 0:
            raise ValueError(f"Nombre de lignes invalide pour {filename}: {length}")
        onset_value = row["sepsis_onset_idx"]
        onset = None if pd.isna(onset_value) else int(onset_value)
        is_sepsis = bool(int(row["is_sepsis"]))
        if is_sepsis and onset is None:
            raise ValueError(f"Patient septique sans index de début du sepsis : {row['patient_id']}")

        entries.append({
            "patient_id": str(row["patient_id"]),
            "hospital": str(row["hospital"]),
            "filename": filename,
            "is_sepsis": is_sepsis,
            "onset": onset,
            "length": length,
        })

    if missing_files:
        preview = ", ".join(missing_files[:5])
        raise FileNotFoundError(
            f"{len(missing_files)} fichier(s) PSV référencé(s) dans le manifeste sont absents "
            f"de {DATA_DIR}. Exemples : {preview}. Réexportez le bundle TEST complet."
        )
    if len(entries) != len(manifest):
        raise RuntimeError(
            f"Export TEST incomplet : {len(entries)} patients trouvés sur {len(manifest)} dans le manifeste."
        )

    _rng.shuffle(entries)
    _index = entries
    # Les PSV sont chargés à la demande pour les patients actifs uniquement.
    _cache.clear()
    return _index


def _eligible(entry, sepsis: bool):
    """Inclut tous les séjours TEST non vides, même courts ou avec sepsis précoce."""
    return entry["length"] > 0 and entry["is_sepsis"] is sepsis


def _pick(conn, sepsis: bool):
    taken = {
        row[0] for row in conn.execute(text(
            "SELECT code_patient FROM patients WHERE source='simulation'"
        )).all()
    }
    for entry in _get_index():
        code = "SIM-" + entry["patient_id"]
        if code in taken or not _eligible(entry, sepsis):
            continue
        return entry
    return None


def _insert_row(conn, patient_db_id, df, index):
    row = df.iloc[index]
    lookup = {column.lower(): column for column in df.columns}
    values = {
        column: row[lookup[column]]
        for column in VITALS_LABS
        if column in lookup
    }
    return pipeline.insert_measurement(conn, patient_db_id, int(row[lookup["iculos"]]), values)


def _available_beds(conn):
    """Beds currently occupied by active simulation patients are never reassigned."""
    occupied = {
        str(row[0]) for row in conn.execute(text(
            "SELECT lit FROM patients WHERE source='simulation' AND statut='actif'"
        )).all() if row[0] is not None
    }
    return [str(bed) for bed in range(1, BED_COUNT + 1) if str(bed) not in occupied]


def _admit(conn, entry, bed):
    filename = entry["filename"]
    df = _read(filename)
    if len(df) != entry["length"]:
        raise ValueError(
            f"Le nombre de lignes de {filename} ne correspond pas au manifeste "
            f"({len(df)} trouvées, {entry['length']} attendues). Réexportez le TEST."
        )
    lookup = {column.lower(): column for column in df.columns}
    first = df.iloc[0]

    def value(column):
        raw = first[lookup[column]] if column in lookup else None
        return None if raw is None or pd.isna(raw) else raw

    onset = entry["onset"]
    if onset is not None:
        # On conserve l'historique juste avant le début du sepsis si possible.
        start = max(0, onset - PRELOAD)
    else:
        # Pour les patients non septiques, ne jamais dépasser la dernière ligne,
        # y compris lorsque le séjour contient moins de PRELOAD heures.
        lower = min(PRELOAD, max(0, len(df) - 1))
        upper = min(max(lower, len(df) - 10), 40)
        start = _rng.randint(lower, upper)

    patient_db_id = conn.execute(text("""
        INSERT INTO patients
            (code_patient, age, sexe, service, lit, unit1, unit2, hosp_adm_time, source)
        VALUES (:code, :age, :sex, 'Réanimation', :bed, :unit1, :unit2, :hosp, 'simulation')
        RETURNING id
    """), {
        "code": "SIM-" + entry["patient_id"],
        "age": float(value("age") if value("age") is not None else 60),
        "sex": "M" if value("gender") == 1 else "F",
        "bed": str(bed),
        "unit1": None if value("unit1") is None else int(value("unit1")),
        "unit2": None if value("unit2") is None else int(value("unit2")),
        "hosp": value("hospadmtime"),
    }).scalar()

    conn.execute(text(
        "INSERT INTO patient_events (patient_id, type, details) "
        "VALUES (:p, 'admission', 'Patient anonymisé simulé depuis le split TEST complet')"
    ), {"p": patient_db_id})

    # Toutes les lignes précédant le curseur sont importées en base. Les labels
    # SepsisLabel restent dans les fichiers de simulation et ne sont jamais insérés.
    for index in range(start):
        measurement_id = _insert_row(conn, patient_db_id, df, index)
        if index >= start - PRED_HIST:
            pipeline.process_measurement(conn, patient_db_id, measurement_id, create_alert=False)

    conn.execute(text("""
        INSERT INTO sim_cursor (patient_id, source_key, next_idx, sepsis_onset_idx)
        VALUES (:p, :filename, :i, :onset)
    """), {"p": patient_db_id, "filename": filename, "i": start, "onset": onset})
    return patient_db_id


def _active_count(conn):
    return int(conn.execute(text(
        "SELECT count(*) FROM sim_cursor c JOIN patients p ON p.id=c.patient_id "
        "WHERE p.statut='actif' AND p.source='simulation'"
    )).scalar() or 0)




def _progress(conn, total_test: int) -> dict:
    row = conn.execute(text("""
        SELECT
            COUNT(*) AS patients_admis,
            COUNT(*) FILTER (WHERE statut = 'actif') AS patients_actifs,
            COUNT(*) FILTER (WHERE statut = 'sorti') AS patients_termines
        FROM patients
        WHERE source = 'simulation'
    """)).mappings().one()
    admitted = int(row["patients_admis"] or 0)
    active = int(row["patients_actifs"] or 0)
    finished = int(row["patients_termines"] or 0)
    return {
        "patients_test_total": total_test,
        "patients_admis": admitted,
        "patients_actifs": active,
        "patients_termines": finished,
        "patients_restants": max(0, total_test - admitted),
    }


def start(preferred_beds=None):
    """Remplit les lits libres sans changer les patients déjà hospitalisés."""
    index = _get_index()
    with engine.begin() as conn:
        active = _active_count(conn)
        septic_active = int(conn.execute(text(
            "SELECT count(*) FROM sim_cursor c JOIN patients p ON p.id=c.patient_id "
            "WHERE p.statut='actif' AND p.source='simulation' AND c.sepsis_onset_idx IS NOT NULL"
        )).scalar() or 0)
        created = 0
        free_beds = _available_beds(conn)
        preferred_beds = list(preferred_beds or [])
        # Priorité aux lits libérés pendant le tick, puis aux autres lits libres.
        ordered_beds = [bed for bed in preferred_beds if bed in free_beds]
        ordered_beds += [bed for bed in free_beds if bed not in ordered_beds]
        while active < N_PATIENTS and ordered_beds:
            want_sepsis = septic_active < N_SEPSIS
            entry = _pick(conn, want_sepsis)
            if entry is None and want_sepsis:
                entry = _pick(conn, False)
            if entry is None:
                break
            bed = ordered_beds.pop(0)
            _admit(conn, entry, bed)
            active += 1
            created += 1
            if entry["is_sepsis"]:
                septic_active += 1

        progress = _progress(conn, len(index))
    return {
        "nouveaux_patients": created,
        "patients_septiques_actifs": septic_active,
        "patients_simultanes_configures": N_PATIENTS,
        "source": "intégralité du split TEST du notebook",
        **progress,
    }


def tick():
    """Avance chaque patient actif d'une heure, puis remplace les dossiers terminés."""
    with engine.begin() as conn:
        cursors = conn.execute(text("""
            SELECT c.patient_id, c.source_key, c.next_idx
            FROM sim_cursor c JOIN patients p ON p.id=c.patient_id
            WHERE p.statut='actif' AND p.source='simulation'
        """)).all()

    processed = 0
    released_beds = []
    for patient_db_id, filename, index in cursors:
        with engine.begin() as conn:
            df = _read(filename)
            if index >= len(df):
                bed = conn.execute(text("SELECT lit FROM patients WHERE id=:p"), {"p": patient_db_id}).scalar()
                if bed is not None:
                    released_beds.append(str(bed))
                _cache.pop(Path(filename).name, None)
                conn.execute(text(
                    "UPDATE patients SET statut='sorti', sorti_le=NOW() WHERE id=:p"
                ), {"p": patient_db_id})
                conn.execute(text(
                    "INSERT INTO patient_events (patient_id, type, details) "
                    "VALUES (:p, 'sortie', 'Fin du dossier de simulation')"
                ), {"p": patient_db_id})
                continue
            measurement_id = _insert_row(conn, patient_db_id, df, index)
            pipeline.process_measurement(conn, patient_db_id, measurement_id)
            conn.execute(text(
                "UPDATE sim_cursor SET next_idx=:i WHERE patient_id=:p"
            ), {"i": index + 1, "p": patient_db_id})
            processed += 1

    refill = start(preferred_beds=released_beds)
    return {"mesures_simulees": processed, **refill}


def reset():
    """Efface uniquement les patients de simulation et toutes leurs données en cascade."""
    with engine.begin() as conn:
        conn.execute(text("DELETE FROM patients WHERE source='simulation'"))
    _cache.clear()
    global _index
    _index = None
    return start()


def status():
    index = _get_index()
    sepsis = sum(1 for entry in index if _eligible(entry, True))
    healthy = sum(1 for entry in index if _eligible(entry, False))
    with engine.begin() as conn:
        progress = _progress(conn, len(index))
    return {
        "configured": True,
        "manifest": str(MANIFEST_PATH),
        "patients_test_disponibles": len(index),
        "lignes_test_total": sum(entry["length"] for entry in index),
        "patients_sepsis_eligibles": sepsis,
        "patients_sans_sepsis_eligibles": healthy,
        "patients_non_eligibles": len(index) - sepsis - healthy,
        "patients_simultanes_configures": N_PATIENTS,
        "patients_sepsis_simultanes_configures": N_SEPSIS,
        **progress,
    }
