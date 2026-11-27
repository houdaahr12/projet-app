from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.orm import Session

from database import get_db
from models import User
# Adapte ces 3 noms à ceux de ton security.py
from security import get_current_user, hash_password, verify_password

router = APIRouter(prefix="/profile", tags=["Profil"])


class ChangePasswordRequest(BaseModel):
    ancien_mot_de_passe: str = Field(min_length=1, max_length=128)
    nouveau_mot_de_passe: str = Field(min_length=8, max_length=72)

    @field_validator("nouveau_mot_de_passe")
    @classmethod
    def check_strength(cls, value: str) -> str:
        # bcrypt est limité à 72 octets (les accents comptent double)
        if len(value.encode("utf-8")) > 72:
            raise ValueError("Le mot de passe est trop long")
        if not any(c.isalpha() for c in value) or not any(c.isdigit() for c in value):
            raise ValueError("Le mot de passe doit contenir une lettre et un chiffre")
        return value


@router.put("/password")
def change_password(
    data: ChangePasswordRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    # 400 et non 401 : la session reste valide, seul le champ saisi est faux
    if not verify_password(data.ancien_mot_de_passe, user.mot_de_passe_hash):
        raise HTTPException(status_code=400, detail="Mot de passe actuel incorrect")

    if data.nouveau_mot_de_passe == data.ancien_mot_de_passe:
        raise HTTPException(
            status_code=400,
            detail="Le nouveau mot de passe doit être différent de l'ancien",
        )

    user.mot_de_passe_hash = hash_password(data.nouveau_mot_de_passe)
    user.doit_changer_mdp = False
    db.commit()

    return {"message": "Mot de passe modifié avec succès"}