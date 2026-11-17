
from sqlalchemy import (
    Column,
    BigInteger,
    String,
    Text,
    Boolean,
    DateTime,
    ForeignKey,
    func
)

from database import Base


class User(Base):

    __tablename__ = "users"

    id = Column(
        BigInteger,
        primary_key=True,
        autoincrement=True
    )

    nom = Column(String(100), nullable=False)

    identifiant = Column(
        String(50),
        nullable=False,
        unique=True
    )

    email = Column(
        String(150),
        unique=True,
        nullable=True
    )

    mot_de_passe_hash = Column(
        Text,
        nullable=False
    )

    role = Column(String(20), nullable=False)

    service = Column(String(100))
    sexe = Column(String(1), nullable=True)   # 'M' ou 'F'
    
    actif = Column(
        Boolean,
        default=True,
        nullable=False
    )

    doit_changer_mdp = Column(
        Boolean,
        default=True,
        nullable=False
    )

    cree_par = Column(
        BigInteger,
        ForeignKey("users.id", ondelete="SET NULL")
    )

    cree_le = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    derniere_connexion = Column(
        DateTime(timezone=True)
    )
