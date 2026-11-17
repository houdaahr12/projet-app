from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import User
from app.schemas import LoginRequest, TokenResponse, UserOut
from app.security import create_access_token, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.identifiant == data.identifiant))

    # Same message for "unknown user" and "wrong password" on purpose
    if user is None or not verify_password(data.mot_de_passe, user.mot_de_passe_hash):
        raise HTTPException(status_code=401, detail="Identifiant ou mot de passe incorrect")

    if not user.actif:
        raise HTTPException(status_code=403, detail="Compte désactivé")

    user.derniere_connexion = datetime.now(timezone.utc)
    db.commit()

    token = create_access_token(user.id, user.role)
    return TokenResponse(access_token=token, user=UserOut.model_validate(user))


@router.get("/me", response_model=UserOut)
def me(current_user: User = Depends(get_current_user)):
    return current_user