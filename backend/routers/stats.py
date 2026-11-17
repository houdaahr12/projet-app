from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db
from models import User
from security import get_current_admin
from services import doctor_service

router = APIRouter(prefix="/admin", tags=["Admin - Statistiques"])


@router.get("/stats")
def get_stats(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    return doctor_service.get_doctor_stats(db)