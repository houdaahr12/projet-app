from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from database import get_db
from models import User
from schemas import DoctorCreate, DoctorUpdate, DoctorResponse
from security import get_current_admin
from services import doctor_service

router = APIRouter(prefix="/admin/doctors", tags=["Admin - Médecins"])


@router.get("", response_model=list[DoctorResponse])
def get_doctors(
    q: str = Query(default="", max_length=100),
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    return doctor_service.list_doctors(db, q)


@router.post("", response_model=DoctorResponse)
def create_doctor(
    data: DoctorCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    return doctor_service.create_doctor(db, data, admin.id)


@router.put("/{doctor_id}", response_model=DoctorResponse)
def update_doctor(
    doctor_id: int,
    data: DoctorUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    return doctor_service.update_doctor(db, doctor_id, data)


@router.delete("/{doctor_id}")
def delete_doctor(
    doctor_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    doctor_service.deactivate_doctor(db, doctor_id)
    return {"message": "Compte médecin désactivé avec succès"}