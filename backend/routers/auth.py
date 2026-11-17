from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import User
from schemas import LoginRequest, LoginResponse
from security import verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["Authentification"])


@router.post("/login", response_model=LoginResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):

    user = db.query(User).filter(
        User.identifiant == data.identifiant
    ).first()

    if not user or not verify_password(data.mot_de_passe, user.mot_de_passe_hash):
        raise HTTPException(
            status_code=401,
            detail="Identifiant ou mot de passe incorrect",
        )

    if not user.actif:
        raise HTTPException(status_code=403, detail="Ce compte est désactivé")

    user.derniere_connexion = datetime.now(timezone.utc)
    db.commit()

    token = create_access_token(user)

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "nom": user.nom,
            "identifiant": user.identifiant,
            "role": user.role,
            "sexe": user.sexe,
        },
    }