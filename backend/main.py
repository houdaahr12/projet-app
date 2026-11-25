import os
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import auth, doctors, stats, simulation, patients
from database import engine, Base
import models
from ml import features, model_service, simulator
from ml.simulation_scheduler import start_scheduler, stop_scheduler

BASE_DIR = Path(__file__).resolve().parent
ARTIFACTS_DIR = BASE_DIR / "ml" / "artifacts"

Base.metadata.create_all(bind=engine)
app = FastAPI(
    title="SepsisCare API",
    description="API SepsisCare — modèle et simulation issus du notebook de recherche",
    version="2.0",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(doctors.router)
app.include_router(stats.router)
app.include_router(simulation.router)
app.include_router(patients.router)


@app.on_event("startup")
def load_ml_assets_and_optional_simulation():
    features.load_artifacts(ARTIFACTS_DIR / "preprocessing_artifacts.joblib")
    model_service.load_model(
        ARTIFACTS_DIR / "lightgbm_sepsis.txt",
        ARTIFACTS_DIR / "inference_bundle.joblib",
    )
    auto_start = os.getenv("SIM_AUTO_START", "false").lower() in {"1", "true", "yes"}
    if auto_start and model_service.is_loaded() and simulator.is_configured():
        try:
            simulator.start()
            start_scheduler()
        except Exception as exc:
            print(f"[simulation] démarrage automatique ignoré : {exc}")
    elif auto_start:
        print("[simulation] auto-start demandé mais artefacts ou manifeste TEST absents")


@app.on_event("shutdown")
def stop_background_simulation():
    stop_scheduler()


@app.get("/")
def home():
    return {
        "message": "SepsisCare API fonctionne correctement",
        "model_loaded": model_service.is_loaded(),
        "simulation_source": "notebook TEST split",
    }
