# backend/routers/patient_create.py
"""Admission manuelle d'un patient, avec une première série de mesures facultative."""
from typing import Literal
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import text

from database import engine
from ml import pipeline
from ml.features import PHYSIO_RANGE, DB2RAW, VITALS_LABS
from models import User
from security import get_current_user

router = APIRouter(prefix="/patients", tags=["Patients"])


class PatientCreate(BaseModel):
    age: float = Field(ge=0, le=120)
    sexe: Literal["M", "F"]
    lit: str = Field(min_length=1, max_length=10)
    service: str | None = Field(default=None, max_length=100)
    unite: Literal["medicale", "chirurgicale"] | None = None
    heures_avant_rea: float | None = Field(default=None, ge=0, le=10000)
    mesures: dict[str, float] = Field(default_factory=dict)


def _check_measurements(values: dict) -> None:
    """Refuse les valeurs que le prétraitement du modèle ignorerait."""
    for column, value in values.items():
        if column not in DB2RAW:
            raise HTTPException(422, f"Mesure inconnue : {column}")
        low, high = PHYSIO_RANGE[DB2RAW[column]]
        valid = low <= value <= high
        if column == "fio2":  # accepte 0,21 ou 21 %
            valid = valid or 20 <= value <= 100
        if column == "calcium":  # calcium ionisé ou total
            valid = valid or 0.5 <= value <= 2.5
        if not valid:
            raise HTTPException(422, f"Valeur hors limites pour {column} : {value}")


@router.post("", status_code=201)
def create_patient(data: PatientCreate, user: User = Depends(get_current_user)):
    if user.role != "medecin":
        raise HTTPException(403, "Seul un médecin peut admettre un patient")
    bed = data.lit.strip()
    if not bed:
        raise HTTPException(422, "Le numéro de lit est obligatoire")
    _check_measurements(data.mesures)
    units = {"medicale": (1, 0), "chirurgicale": (0, 1)}.get(data.unite, (None, None))

    # 1) Patient + mesures : tout ou rien
    with engine.begin() as conn:
        occupied = conn.execute(text(
            "SELECT 1 FROM patients WHERE statut='actif' AND lit=:bed LIMIT 1"
        ), {"bed": bed}).first()
        if occupied:
            raise HTTPException(409, f"Le lit {bed} est déjà occupé")

        patient_id = conn.execute(text("""
            INSERT INTO patients (code_patient, age, sexe, service, lit,
                                  unit1, unit2, hosp_adm_time, source, cree_par)
            VALUES (:code, :age, :sexe, :service, :lit,
                    :unit1, :unit2, :hosp, 'manuel', :user)
            RETURNING id
        """), {
            "code": uuid4().hex[:20],  # code temporaire
            "age": data.age,
            "sexe": data.sexe,
            "service": (data.service or "").strip() or "Réanimation",
            "lit": bed,
            "unit1": units[0],
            "unit2": units[1],
            # Convention du jeu de données : négatif = arrivé à l'hôpital avant la réa
            "hosp": None if data.heures_avant_rea is None else -data.heures_avant_rea,
            "user": user.id,
        }).scalar_one()

        code = f"P-{patient_id:05d}"
        conn.execute(text("UPDATE patients SET code_patient=:code WHERE id=:p"),
                     {"code": code, "p": patient_id})
        # Sans cette ligne, le médecin ne verrait pas son patient
        conn.execute(text(
            "INSERT INTO patient_soignants (patient_id, user_id) VALUES (:p, :u)"
        ), {"p": patient_id, "u": user.id})
        conn.execute(text(
            "INSERT INTO patient_events (patient_id, user_id, type, details) "
            "VALUES (:p, :u, 'admission', 'Admission saisie manuellement')"
        ), {"p": patient_id, "u": user.id})

        measurement_id = None
        if data.mesures:
            values = {column: data.mesures.get(column) for column in VITALS_LABS}
            measurement_id = pipeline.insert_measurement(conn, patient_id, 1, values)
            conn.execute(text("UPDATE measurements SET saisi_par=:u WHERE id=:m"),
                         {"u": user.id, "m": measurement_id})

    # 2) Prédiction à part : une erreur du modèle ne fait pas perdre la saisie
    predicted = False
    if measurement_id is not None:
        try:
            with engine.begin() as conn:
                pipeline.process_measurement(conn, patient_id, measurement_id)
            predicted = True
        except Exception as exc:
            print(f"[patients] prédiction impossible pour {code} : {exc}")

    return {
        "id": patient_id,
        "code_patient": code,
        "mesures_enregistrees": measurement_id is not None,
        "prediction_calculee": predicted,
    }