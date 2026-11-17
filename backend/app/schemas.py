from pydantic import BaseModel


class LoginRequest(BaseModel):
    identifiant: str
    mot_de_passe: str


class UserOut(BaseModel):
    id: int
    nom: str
    identifiant: str
    role: str
    service: str | None = None
    doit_changer_mdp: bool

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut