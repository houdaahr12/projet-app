from sqlalchemy import select

from app.database import SessionLocal
from app.models import User
from app.security import hash_password

db = SessionLocal()

if db.scalar(select(User).where(User.identifiant == "dr.houda")):
    print("User already exists")
else:
    db.add(User(
        nom="Dr houda",
        identifiant="dr.houda",
        email="houda@test.com",
        mot_de_passe_hash=hash_password("houda!"),
        role="medecin",
        service="Cardiologie",
        actif=True,
        doit_changer_mdp=False,
    ))
    db.commit()
    print("Test doctor created")

db.close()