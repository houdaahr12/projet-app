from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import auth, doctors, stats
from database import engine, Base      
import models                          

Base.metadata.create_all(bind=engine)
app = FastAPI(
    title="SepsisCare API",
    description="Administration des médecins réanimateurs",
    version="1.0",
)

# CORS : autoriser Flutter Web pendant le développement
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Branchement des routeurs
app.include_router(auth.router)
app.include_router(doctors.router)
app.include_router(stats.router)


@app.get("/")
def home():
    return {"message": "SepsisCare API fonctionne correctement"}