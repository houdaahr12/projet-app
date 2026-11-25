
from database import SessionLocal
from models import User
from security import hash_password

def create_admin():

    db = SessionLocal()

    try:
        identifiant = input("Identifiant administrateur : ")
        nom = input("Nom complet : ")
        email = input("Email : ")
        password = input("Mot de passe : ")

        existing = db.query(User).filter(
            User.identifiant == identifiant
        ).first()

        if existing:
            print("Cet identifiant existe déjà.")
            return

        admin = User(
            nom=nom,
            identifiant=identifiant,
            email=email or None,
            mot_de_passe_hash=hash_password(password),
            role="admin",
            service="Administration",
            actif=True,
            doit_changer_mdp=False
        )

        db.add(admin)
        db.commit()

        print("Administrateur créé avec succès !")

    finally:
        db.close()


if __name__ == "__main__":
    create_admin()
