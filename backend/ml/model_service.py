"""Chargement du Booster LightGBM et du calibrateur exportés par le notebook."""
from pathlib import Path
import numpy as np
import pandas as pd

_model = None
_bundle = None
_features = []


def load_model(model_path: str | Path, bundle_path: str | Path) -> bool:
    global _model, _bundle, _features
    model_path, bundle_path = Path(model_path), Path(bundle_path)
    if not model_path.is_file() or not bundle_path.is_file():
        _model = _bundle = None
        _features = []
        print(f"[model] artefacts manquants : modèle={model_path.exists()}, bundle={bundle_path.exists()}")
        return False

    import joblib
    import lightgbm as lgb
    booster = lgb.Booster(model_file=str(model_path))
    bundle = joblib.load(bundle_path)
    required = {"features", "calibrator", "yellow_threshold", "red_threshold", "red_rule"}
    missing = required.difference(bundle)
    if missing:
        raise ValueError(f"inference_bundle.joblib incomplet : {sorted(missing)}")
    if len(bundle["features"]) != booster.num_feature():
        raise ValueError(
            f"Incompatibilité modèle/bundle : {booster.num_feature()} features dans le modèle, "
            f"{len(bundle['features'])} dans le bundle. Réexportez les deux depuis le même notebook."
        )
    _model, _bundle = booster, bundle
    _features = list(bundle["features"])
    print(f"[model] LightGBM chargé : {len(_features)} features, seuil jaune="
          f"{bundle['yellow_threshold']:.4f}, seuil rouge={bundle['red_threshold']:.4f}")
    return True


def is_loaded() -> bool:
    return _model is not None and _bundle is not None


def active_name() -> str:
    return "lightgbm_sepsis_notebook" if is_loaded() else "model_not_loaded"


def feature_names() -> list[str]:
    if not is_loaded():
        raise RuntimeError("Le modèle notebook n'est pas chargé. Vérifiez les artefacts exportés.")
    return _features


def thresholds() -> dict:
    if not is_loaded():
        raise RuntimeError("Le modèle notebook n'est pas chargé.")
    return _bundle


def _top_factors(X: pd.DataFrame) -> list[dict]:
    try:
        contrib = np.asarray(_model.predict(X, pred_contrib=True))[0, :-1]
        indices = np.argsort(-np.abs(contrib))[:3]
        return [
            {"variable": str(_features[i]), "impact": round(float(contrib[i]), 4)}
            for i in indices
        ]
    except Exception as exc:
        print(f"[model] explication indisponible : {exc}")
        return []


def predict(X: pd.DataFrame) -> tuple[float, list[dict]]:
    """Prédit le score brut puis applique le calibrateur isotonic du notebook."""
    if not is_loaded():
        raise RuntimeError("Modèle/artefacts absents. Exportez-les depuis le notebook avant la simulation.")
    Xa = X.reindex(columns=_features).astype("float32")
    raw_score = np.asarray(_model.predict(Xa), dtype=float).reshape(-1)
    calibrated = np.asarray(_bundle["calibrator"].predict(raw_score), dtype=float).reshape(-1)
    score = float(np.clip(calibrated[0], 0.0, 1.0))
    return score, _top_factors(Xa)


def classify_level(score: float, previous_risk: float | None = None) -> str:
    """Applique les seuils jaune/rouge choisis dans la validation du notebook."""
    cfg = thresholds()
    yellow = float(cfg["yellow_threshold"])
    red = float(cfg["red_threshold"])
    rule = str(cfg["red_rule"])
    strict_red = score >= red

    lag = int(cfg.get("rising_lag_hours", 6))
    ratio = float(cfg.get("rising_ratio", 2.0))
    rising_red = (
        previous_risk is not None
        and score >= yellow
        and score >= ratio * float(previous_risk)
    )
    if rule == "seuil strict":
        red_alert = strict_red
    elif rule == "montée rapide":
        red_alert = rising_red
    elif rule == "seuil strict ou montée rapide":
        red_alert = strict_red or rising_red
    else:
        # Une valeur inconnue ne doit pas inventer une nouvelle règle clinique.
        raise ValueError(f"Règle rouge inconnue dans inference_bundle.joblib : {rule}")

    if red_alert:
        return "alerte"
    if score >= yellow:
        return "surveillance"
    return "normal"
