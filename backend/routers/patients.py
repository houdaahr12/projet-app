from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db
from models import User
from security import get_current_user

router = APIRouter(prefix="/patients", tags=["Patients"])


PATIENT_SUMMARY_SELECT = """
    SELECT
        p.id,
        p.code_patient,
        p.age,
        p.sexe,
        p.service,
        p.lit,
        p.unit1,
        p.unit2,
        p.hosp_adm_time,
        p.admis_icu_le,
        p.statut,
        p.sorti_le,
        p.source,
        last_m.heure_icu AS derniere_heure_icu,
        last_pr.score AS dernier_score,
        last_pr.niveau AS dernier_niveau,
        last_pr.calcule_le AS derniere_prediction_le
    FROM patients p
    LEFT JOIN LATERAL (
        SELECT m.heure_icu
        FROM measurements m
        WHERE m.patient_id = p.id
        ORDER BY m.heure_icu DESC
        LIMIT 1
    ) last_m ON TRUE
    LEFT JOIN LATERAL (
        SELECT pr.score, pr.niveau, pr.calcule_le
        FROM predictions pr
        WHERE pr.patient_id = p.id
        ORDER BY pr.calcule_le DESC
        LIMIT 1
    ) last_pr ON TRUE
"""


def _access_filter(user: User) -> tuple[str, dict]:
    """Doctors can see simulation patients and patients assigned to them."""
    if user.role == "admin":
        return "", {}
    return (
        """ AND (
            p.source = 'simulation'
            OR EXISTS (
                SELECT 1 FROM patient_soignants ps
                WHERE ps.patient_id = p.id AND ps.user_id = :user_id
            )
        )""",
        {"user_id": user.id},
    )


def _ensure_patient_access(db: Session, patient_id: int, user: User) -> None:
    access_sql, params = _access_filter(user)
    params["patient_id"] = patient_id
    row = db.execute(
        text("SELECT p.id FROM patients p WHERE p.id = :patient_id " + access_sql),
        params,
    ).first()
    if row is None:
        # Avoid disclosing whether an unassigned patient exists.
        raise HTTPException(status_code=404, detail="Patient introuvable")


def _page(items, total: int, limit: int, offset: int):
    return {
        "items": [dict(item) for item in items],
        "total": int(total),
        "limit": limit,
        "offset": offset,
        "has_more": offset + len(items) < int(total),
    }


@router.get("")
def list_patients(
    q: str = Query(default="", max_length=100),
    statut: Literal["actif", "sorti"] | None = None,
    source: Literal["manuel", "simulation"] | None = None,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Return a paginated patient list. Doctors can see all replayed TEST patients."""
    conditions = []
    params = {"limit": limit, "offset": offset}
    access_sql, access_params = _access_filter(user)
    params.update(access_params)

    if statut:
        conditions.append("p.statut = :statut")
        params["statut"] = statut
    if source:
        conditions.append("p.source = :source")
        params["source"] = source
    if q.strip():
        conditions.append("p.code_patient ILIKE :search")
        params["search"] = f"%{q.strip()}%"

    where_sql = " WHERE " + " AND ".join(conditions) if conditions else " WHERE TRUE"
    query = PATIENT_SUMMARY_SELECT + where_sql + access_sql + """
        ORDER BY CASE WHEN p.statut = 'actif' THEN 0 ELSE 1 END, p.cree_le DESC, p.id DESC
        LIMIT :limit OFFSET :offset
    """
    count_query = "SELECT COUNT(*) FROM patients p" + where_sql + access_sql

    items = db.execute(text(query), params).mappings().all()
    count_params = {key: value for key, value in params.items() if key not in {"limit", "offset"}}
    total = db.execute(text(count_query), count_params).scalar_one()
    return _page(items, total, limit, offset)


@router.get("/{patient_id}")
def get_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    _ensure_patient_access(db, patient_id, user)
    row = db.execute(
        text(PATIENT_SUMMARY_SELECT + " WHERE p.id = :patient_id"),
        {"patient_id": patient_id},
    ).mappings().first()
    if row is None:
        raise HTTPException(status_code=404, detail="Patient introuvable")
    return dict(row)


@router.get("/{patient_id}/measurements")
def get_patient_measurements(
    patient_id: int,
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    _ensure_patient_access(db, patient_id, user)
    total = db.execute(
        text("SELECT COUNT(*) FROM measurements WHERE patient_id = :patient_id"),
        {"patient_id": patient_id},
    ).scalar_one()
    rows = db.execute(text("""
        SELECT
            id, patient_id, heure_icu, mesure_le, saisi_par,
            hr, o2sat, temp, sbp, map, dbp, resp, etco2,
            baseexcess, hco3, fio2, ph, paco2, sao2, ast, bun,
            alkalinephos, calcium, chloride, creatinine, bilirubin_direct,
            glucose, lactate, magnesium, phosphate, potassium,
            bilirubin_total, troponini, hct, hgb, ptt, wbc,
            fibrinogen, platelets
        FROM measurements
        WHERE patient_id = :patient_id
        ORDER BY heure_icu DESC
        LIMIT :limit OFFSET :offset
    """), {"patient_id": patient_id, "limit": limit, "offset": offset}).mappings().all()
    # Return the selected (most recent) window in chronological order for charts.
    return _page(list(reversed(rows)), total, limit, offset)


@router.get("/{patient_id}/predictions")
def get_patient_predictions(
    patient_id: int,
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    _ensure_patient_access(db, patient_id, user)
    total = db.execute(
        text("SELECT COUNT(*) FROM predictions WHERE patient_id = :patient_id"),
        {"patient_id": patient_id},
    ).scalar_one()
    rows = db.execute(text("""
        SELECT pr.id, pr.patient_id, pr.measurement_id, m.heure_icu,
               pr.model_version_id, pr.score, pr.niveau, pr.facteurs, pr.calcule_le
        FROM predictions pr
        JOIN measurements m ON m.id = pr.measurement_id
        WHERE pr.patient_id = :patient_id
        ORDER BY m.heure_icu DESC, pr.id DESC
        LIMIT :limit OFFSET :offset
    """), {"patient_id": patient_id, "limit": limit, "offset": offset}).mappings().all()
    return _page(list(reversed(rows)), total, limit, offset)


@router.get("/{patient_id}/alerts")
def get_patient_alerts(
    patient_id: int,
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    _ensure_patient_access(db, patient_id, user)
    total = db.execute(
        text("SELECT COUNT(*) FROM alerts WHERE patient_id = :patient_id"),
        {"patient_id": patient_id},
    ).scalar_one()
    rows = db.execute(text("""
        SELECT id, patient_id, prediction_id, score, facteurs, statut, creee_le,
               vue_par, vue_le, prise_en_charge_par, prise_en_charge_le,
               note, cloturee_le
        FROM alerts
        WHERE patient_id = :patient_id
        ORDER BY creee_le DESC, id DESC
        LIMIT :limit OFFSET :offset
    """), {"patient_id": patient_id, "limit": limit, "offset": offset}).mappings().all()
    return _page(list(reversed(rows)), total, limit, offset)


@router.get("/{patient_id}/events")
def get_patient_events(
    patient_id: int,
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    _ensure_patient_access(db, patient_id, user)
    total = db.execute(
        text("SELECT COUNT(*) FROM patient_events WHERE patient_id = :patient_id"),
        {"patient_id": patient_id},
    ).scalar_one()
    rows = db.execute(text("""
        SELECT id, patient_id, user_id, type, details, cree_le
        FROM patient_events
        WHERE patient_id = :patient_id
        ORDER BY cree_le DESC, id DESC
        LIMIT :limit OFFSET :offset
    """), {"patient_id": patient_id, "limit": limit, "offset": offset}).mappings().all()
    return _page(list(reversed(rows)), total, limit, offset)
