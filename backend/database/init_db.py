from pathlib import Path
import re
from sqlalchemy import text
from database import engine  # change to `from db import engine` if your module is named db.py

SCHEMA_PATH = Path(__file__).resolve().parent / "schema.sql"


def init_db() -> None:
    sql = SCHEMA_PATH.read_text(encoding="utf-8")
    sql = re.sub(r"(?m)^\[\d{2}/\d{2}/\d{4} \d{2}:\d{2}\] [^:]+: ?", "", sql)

    with engine.begin() as conn:
        exists = conn.execute(text("SELECT to_regclass('public.users')")).scalar()
        conn.exec_driver_sql(sql)
        if exists:
            print("schema.sql vérifié / mis à jour (tables déjà présentes).")
        else:
            print("schema.sql appliqué.")


if __name__ == "__main__":
    init_db()