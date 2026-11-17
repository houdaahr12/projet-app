from datetime import datetime
from sqlalchemy import BigInteger, Boolean, DateTime, String, Text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    nom: Mapped[str] = mapped_column(String(100))
    identifiant: Mapped[str] = mapped_column(String(50), unique=True)
    email: Mapped[str | None] = mapped_column(String(150))
    mot_de_passe_hash: Mapped[str] = mapped_column(Text)
    role: Mapped[str] = mapped_column(String(20))
    service: Mapped[str | None] = mapped_column(String(100))
    actif: Mapped[bool] = mapped_column(Boolean)
    doit_changer_mdp: Mapped[bool] = mapped_column(Boolean)
    derniere_connexion: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))