from pydantic import BaseModel, ConfigDict, Field, EmailStr, field_validator
from typing import Optional
from typing import Optional, Literal

def vide_en_none(valeur):
    """Transforme une chaîne vide ou faite d'espaces en None."""
    if isinstance(valeur, str) and not valeur.strip():
        return None
    return valeur


class LoginRequest(BaseModel):
    identifiant: str
    mot_de_passe: str


class DoctorCreate(BaseModel):
    nom: str = Field(min_length=2, max_length=100)
    identifiant: str = Field(min_length=3, max_length=50)
    sexe: Literal["M", "F"]
    email: Optional[EmailStr] = None
    mot_de_passe: str = Field(min_length=8)
    service: Optional[str] = Field(default=None, max_length=100)

    @field_validator("email", "service", mode="before")
    @classmethod
    def champs_vides(cls, v):
        return vide_en_none(v)


class DoctorUpdate(BaseModel):
    nom: Optional[str] = Field(default=None, min_length=2, max_length=100)
    identifiant: Optional[str] = Field(default=None, min_length=3, max_length=50)
    sexe: Optional[Literal["M", "F"]] = None
    email: Optional[EmailStr] = None
    mot_de_passe: Optional[str] = Field(default=None, min_length=8)
    service: Optional[str] = Field(default=None, max_length=100)
    actif: Optional[bool] = None

    @field_validator("email", "service", "mot_de_passe", mode="before")
    @classmethod
    def champs_vides(cls, v):
        return vide_en_none(v)


class DoctorResponse(BaseModel):
    id: int
    nom: str
    identifiant: str
    sexe: Optional[str] = None    
    email: Optional[str]
    role: str
    service: Optional[str]
    actif: bool
    doit_changer_mdp: bool

    model_config = ConfigDict(from_attributes=True)


class LoginResponse(BaseModel):
    access_token: str
    token_type: str
    user: dict