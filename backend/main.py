import os
from dotenv import load_dotenv
from fastapi import FastAPI
from sqlalchemy import create_engine, text

load_dotenv()
engine = create_engine(os.getenv("DATABASE_URL"))
app = FastAPI()

@app.get("/")
def root():
    return {"message": "API is running: hey houdaa"}

@app.get("/db-test")
def db_test():
    with engine.connect() as conn:
        return {"db": conn.execute(text("SELECT version()")).scalar()}