from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from models import User
from schemas import DoctorCreate, DoctorUpdate
from security import hash_password


def list_doctors(db: Session, q: str = ""):
    query = db.query(User).filter(User.role == "medecin")

    if q.strip():
        search = f"%{q.strip()}%"
        query = query.filter(
            (User.nom.ilike(search))
            | (User.identifiant.ilike(search))
            | (User.email.ilike(search))
        )

    return query.order_by(User.cree_le.desc()).all()


def get_doctor_or_404(db: Session, doctor_id: int) -> User:
    doctor = db.query(User).filter(
        User.id == doctor_id,
        User.role == "medecin",
    ).first()

    if not doctor:
        raise HTTPException(status_code=404, detail="Médecin introuvable")

    return doctor


def create_doctor(db: Session, data: DoctorCreate, admin_id: int) -> User:
    doctor = User(
        nom=data.nom,
        identifiant=data.identifiant,
        sexe=data.sexe,
        email=data.email,
        mot_de_passe_hash=hash_password(data.mot_de_passe),
        role="medecin",
        service=data.service,
        actif=True,
        doit_changer_mdp=True,
        cree_par=admin_id,
    )
    db.add(doctor)

    try:
        db.commit()
        db.refresh(doctor)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Cet identifiant ou cet email existe déjà",
        )

    return doctor


def update_doctor(db: Session, doctor_id: int, data: DoctorUpdate) -> User:
    doctor = get_doctor_or_404(db, doctor_id)

    updates = data.model_dump(exclude_unset=True)

    for field, value in updates.items():
        if field == "mot_de_passe":
            if value:
                doctor.mot_de_passe_hash = hash_password(value)
                doctor.doit_changer_mdp = True

        elif field in ("nom", "identifiant", "actif", "sexe") and value is None:
            continue  # ces champs ne peuvent pas être vides

        else:
            setattr(doctor, field, value)

    try:
        db.commit()
        db.refresh(doctor)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Identifiant ou email déjà utilisé",
        )

    return doctor


def deactivate_doctor(db: Session, doctor_id: int) -> None:
    doctor = get_doctor_or_404(db, doctor_id)

    # Suppression logique pour conserver l'historique médical
    doctor.actif = False
    db.commit()


def get_doctor_stats(db: Session) -> dict:
    total = db.query(User).filter(User.role == "medecin").count()
    actifs = db.query(User).filter(
        User.role == "medecin",
        User.actif == True,  # noqa: E712
    ).count()

    return {
        "total_medecins": total,
        "medecins_actifs": actifs,
        "medecins_inactifs": total - actifs,
    }