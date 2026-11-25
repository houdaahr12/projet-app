from fastapi import APIRouter, Depends, HTTPException
from models import User
from security import get_current_admin
from ml import simulator, model_service
from ml.simulation_scheduler import start_scheduler, stop_scheduler, scheduler_running

router = APIRouter(prefix="/simulation", tags=["Simulation TEST"])


def _check_ready():
    if not model_service.is_loaded():
        raise HTTPException(
            status_code=503,
            detail="Modèle du notebook absent. Copiez lightgbm_sepsis.txt, inference_bundle.joblib et preprocessing_artifacts.joblib dans ml/artifacts.",
        )
    if not simulator.is_configured():
        raise HTTPException(
            status_code=503,
            detail="Jeu TEST absent. Exécutez la cellule d'export du notebook et copiez sim_data_test dans le backend.",
        )


@router.get("/status")
def get_status(admin: User = Depends(get_current_admin)):
    _check_ready()
    return {**simulator.status(), "scheduler_actif": scheduler_running()}


@router.post("/start")
def start_simulation(admin: User = Depends(get_current_admin)):
    _check_ready()
    try:
        result = simulator.start()
        start_scheduler()
        return {"message": "Simulation démarrée depuis le jeu TEST", **result}
    except (FileNotFoundError, ValueError, RuntimeError) as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@router.post("/tick")
def advance_simulation(admin: User = Depends(get_current_admin)):
    _check_ready()
    try:
        return simulator.tick()
    except (FileNotFoundError, ValueError, RuntimeError) as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@router.post("/pause")
def pause_simulation(admin: User = Depends(get_current_admin)):
    stop_scheduler()
    return {"message": "Simulation mise en pause", "scheduler_actif": False}


@router.post("/reset")
def reset_simulation(admin: User = Depends(get_current_admin)):
    _check_ready()
    stop_scheduler()
    try:
        result = simulator.reset()
        start_scheduler()
        return {"message": "Simulation réinitialisée avec le jeu TEST", **result}
    except (FileNotFoundError, ValueError, RuntimeError) as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
