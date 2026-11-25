"""Preprocessing et feature engineering identiques au notebook Sepsis."""
from pathlib import Path
import numpy as np
import pandas as pd

DB2RAW = {
    "hr": "HR", "o2sat": "O2Sat", "temp": "Temp", "sbp": "SBP", "map": "MAP", "dbp": "DBP",
    "resp": "Resp", "etco2": "EtCO2", "baseexcess": "BaseExcess", "hco3": "HCO3", "fio2": "FiO2",
    "ph": "pH", "paco2": "PaCO2", "sao2": "SaO2", "ast": "AST", "bun": "BUN",
    "alkalinephos": "Alkalinephos", "calcium": "Calcium", "chloride": "Chloride",
    "creatinine": "Creatinine", "bilirubin_direct": "Bilirubin_direct", "glucose": "Glucose",
    "lactate": "Lactate", "magnesium": "Magnesium", "phosphate": "Phosphate",
    "potassium": "Potassium", "bilirubin_total": "Bilirubin_total", "troponini": "TroponinI",
    "hct": "Hct", "hgb": "Hgb", "ptt": "PTT", "wbc": "WBC", "fibrinogen": "Fibrinogen",
    "platelets": "Platelets",
}
VITALS_LABS = list(DB2RAW)
VITALS = ["HR", "O2Sat", "Temp", "SBP", "MAP", "DBP", "Resp", "EtCO2"]
LABS = [
    "BaseExcess", "HCO3", "FiO2", "pH", "PaCO2", "SaO2", "AST", "BUN", "Alkalinephos", "Calcium",
    "Chloride", "Creatinine", "Bilirubin_direct", "Glucose", "Lactate", "Magnesium", "Phosphate",
    "Potassium", "Bilirubin_total", "TroponinI", "Hct", "Hgb", "PTT", "WBC", "Fibrinogen", "Platelets",
    "Calcium_ionized",
]
PHYSIO_RANGE = {
    "HR": (20, 250), "O2Sat": (50, 100), "Temp": (30, 43), "SBP": (40, 300), "MAP": (20, 250),
    "DBP": (20, 200), "Resp": (4, 60), "EtCO2": (5, 100), "BaseExcess": (-30, 30), "HCO3": (5, 50),
    "FiO2": (0.2, 1.0), "pH": (6.8, 7.8), "PaCO2": (10, 150), "SaO2": (40, 100), "AST": (1, 10000),
    "BUN": (1, 200), "Alkalinephos": (5, 3000), "Calcium": (3, 20), "Chloride": (60, 140),
    "Creatinine": (0.1, 30), "Bilirubin_direct": (0, 30), "Glucose": (20, 800), "Lactate": (0.1, 30),
    "Magnesium": (0.5, 10), "Phosphate": (0.5, 15), "Potassium": (1.5, 9), "Bilirubin_total": (0.1, 60),
    "TroponinI": (0, 500), "Hct": (10, 65), "Hgb": (3, 25), "PTT": (10, 250), "WBC": (0.1, 100),
    "Fibrinogen": (20, 1500), "Platelets": (1, 1500),
}

_ART = None


def load_artifacts(path: str | Path) -> bool:
    """Charge preprocessing_artifacts.joblib exporté par le notebook."""
    global _ART
    path = Path(path)
    if not path.is_file():
        _ART = None
        print(f"[features] artefact introuvable : {path}")
        return False
    import joblib
    art = joblib.load(path)
    required = {"dropped_columns", "ts_cols", "roll_window", "physio_range"}
    missing = required.difference(art)
    if missing:
        raise ValueError(f"Artefact de preprocessing incomplet : {sorted(missing)}")
    _ART = art
    print(f"[features] preprocessing chargé : {len(art['ts_cols'])} variables temporelles, "
          f"{len(art['dropped_columns'])} colonnes retirées")
    return True


def get_art():
    if _ART is None:
        raise RuntimeError("preprocessing_artifacts.joblib absent. Exportez-le depuis le notebook.")
    return _ART


def kept_db_columns():
    art = get_art()
    ts = set(art["ts_cols"])
    return [db for db, raw in DB2RAW.items() if raw in ts]


def clean(df_in: pd.DataFrame, art: dict) -> pd.DataFrame:
    """Copie des règles clean() du notebook, sans calcul utilisant le futur."""
    df = df_in.copy()
    for col in ["Calcium", "FiO2", "Unit1", "Unit2", "Age", "HospAdmTime"]:
        if col not in df:
            df[col] = np.nan

    ionized = df["Calcium"] < 3
    df["Calcium_ionized"] = df["Calcium"].where(ionized)
    df.loc[ionized, "Calcium"] = np.nan
    bad_ion = (df["Calcium_ionized"] < 0.5) | (df["Calcium_ionized"] > 2.5)
    df.loc[bad_ion, "Calcium_ionized"] = np.nan

    percent = (df["FiO2"] > 1) & (df["FiO2"] <= 100)
    df.loc[percent, "FiO2"] = df.loc[percent, "FiO2"] / 100
    for col, (lo, hi) in art["physio_range"].items():
        if col in df.columns:
            bad = (df[col] < lo) | (df[col] > hi)
            df.loc[bad, col] = np.nan

    df["Unit"] = np.select([df["Unit1"] == 1, df["Unit2"] == 1], [1, 2], default=0).astype("int8")
    df = df.drop(columns=["Unit1", "Unit2"])
    df["Age_ge90"] = (df["Age"] >= 90).astype("int8")
    hours_in_hospital = (-df["HospAdmTime"]).clip(lower=0)
    df["HospAdm_log"] = np.log1p(hours_in_hospital).astype("float32")
    return df.drop(columns=["HospAdmTime"])


def build_features(d: pd.DataFrame, art: dict) -> pd.DataFrame:
    """Construit les 165 features de base du notebook sur l'historique connu."""
    ts_cols = [c for c in art["ts_cols"] if c in d.columns]
    window = int(art["roll_window"])
    vitals_roll = [v for v in ["HR", "O2Sat", "Temp", "SBP", "MAP", "DBP", "Resp"] if v in ts_cols]
    d = d.sort_values(["Patient_ID", "ICULOS"]).reset_index(drop=True)
    pid = d["Patient_ID"]
    parts = {}

    ff = d[ts_cols].groupby(pid).ffill()
    for col in ts_cols:
        parts[col] = ff[col]

    obs = d[ts_cols].notna()
    for col in ts_cols:
        parts[f"{col}_obs"] = obs[col].astype("int8")

    t = d["ICULOS"].to_numpy("float32")[:, None]
    last_seen = pd.DataFrame(np.where(obs.to_numpy(), t, np.nan), columns=ts_cols, index=d.index)
    last_seen = last_seen.groupby(pid).ffill().to_numpy()
    since = np.where(np.isnan(last_seen), t, t - last_seen).astype("float32")
    for i, col in enumerate(ts_cols):
        parts[f"{col}_hours_since"] = pd.Series(since[:, i], index=d.index)

    labs_kept = [c for c in LABS if c in ts_cols]
    if labs_kept:
        counts = obs[labs_kept].astype("int16").groupby(pid).cumsum()
        for col in labs_kept:
            parts[f"{col}_count"] = counts[col]

    if vitals_roll:
        roll = ff[vitals_roll].groupby(pid).rolling(window, min_periods=1)
        for stat in ["mean", "min", "max", "std"]:
            result = getattr(roll, stat)().reset_index(level=0, drop=True).sort_index()
            for col in vitals_roll:
                parts[f"{col}_{stat}{window}"] = result[col]
        shifted = ff[vitals_roll].groupby(pid).shift(window)
        for col in vitals_roll:
            parts[f"{col}_delta{window}"] = ff[col] - shifted[col]

    def has(*names):
        return all(n in ff.columns for n in names)

    if has("HR", "SBP"):
        parts["shock_index"] = ff["HR"] / ff["SBP"]
    if has("SBP", "DBP"):
        parts["pulse_pressure"] = ff["SBP"] - ff["DBP"]
    if has("MAP"):
        parts["map_below_65"] = (ff["MAP"] < 65).astype("int8").where(ff["MAP"].notna())
    if has("Lactate"):
        parts["lactate_above_2"] = (ff["Lactate"] > 2).astype("int8").where(ff["Lactate"].notna())
    if has("O2Sat", "FiO2"):
        parts["spo2_fio2_ratio"] = ff["O2Sat"] / ff["FiO2"]
    if has("BUN", "Creatinine"):
        parts["bun_creatinine_ratio"] = ff["BUN"] / ff["Creatinine"]
    if has("Temp", "HR", "Resp", "WBC"):
        parts["sirs_count"] = (
            ((ff["Temp"] > 38) | (ff["Temp"] < 36)).astype("int8")
            + (ff["HR"] > 90).astype("int8")
            + (ff["Resp"] > 20).astype("int8")
            + ((ff["WBC"] > 12) | (ff["WBC"] < 4)).astype("int8")
        )
    if has("Resp", "SBP"):
        parts["qsofa_like"] = (ff["Resp"] >= 22).astype("int8") + (ff["SBP"] <= 100).astype("int8")

    for col in ["Age", "Age_ge90", "Gender", "Unit", "HospAdm_log", "ICULOS"]:
        parts[col] = d[col]

    feats = pd.concat(parts, axis=1).replace([np.inf, -np.inf], np.nan)
    float_cols = feats.select_dtypes("float64").columns
    feats[float_cols] = feats[float_cols].astype("float32")
    # Le notebook conserve Patient_ID/Hospital pour les opérations groupées et les audits,
    # puis les exclut de FEATURES avant l'apprentissage.
    meta_cols = [col for col in ["Patient_ID", "Hospital", "SepsisLabel", "split"] if col in d.columns]
    meta = d[meta_cols].reset_index(drop=True) if meta_cols else pd.DataFrame(index=feats.index)
    return pd.concat([meta, feats.reset_index(drop=True)], axis=1)


def _rolling_stat(grouped, columns, window, stat):
    result = getattr(grouped[columns].rolling(window, min_periods=1), stat)()
    return result.reset_index(level=0, drop=True).sort_index()


def _points_high_is_bad(values, cuts):
    return sum((values >= cut).astype("int8") for cut in cuts)


def _points_low_is_bad(values, cuts):
    return sum((values < cut).astype("int8") for cut in cuts)


def add_features(frame: pd.DataFrame) -> pd.DataFrame:
    """Copie des 41 features ajoutées au notebook (section 14)."""
    grouped = frame.groupby("Patient_ID", sort=False)
    new = {}
    vital_trends = ["HR", "MAP", "Resp", "Temp", "O2Sat", "SBP"]
    worst_high = ["HR", "Resp", "Temp", "Lactate", "Creatinine", "BUN", "WBC", "Bilirubin_total"]
    worst_low = ["MAP", "SBP", "O2Sat", "Platelets"]
    lab_changes = ["Lactate", "Creatinine", "Platelets", "WBC"]

    mean12 = _rolling_stat(grouped, vital_trends, 12, "mean")
    mean24 = _rolling_stat(grouped, vital_trends, 24, "mean")
    for col in vital_trends:
        new[f"{col}_mean12"] = mean12[col]
        new[f"{col}_mean24"] = mean24[col]
        new[f"{col}_trend"] = frame[f"{col}_mean6"] - mean24[col]

    for col in worst_high:
        new[f"{col}_max_since_admission"] = grouped[col].cummax()
    for col in worst_low:
        new[f"{col}_min_since_admission"] = grouped[col].cummin()
    for col in lab_changes:
        new[f"{col}_change12"] = frame[col] - grouped[col].shift(12)

    new["sofa_resp"] = _points_low_is_bad(frame["spo2_fio2_ratio"], [400, 315, 235, 150])
    new["sofa_coag"] = _points_low_is_bad(frame["Platelets"], [150, 100, 50, 20])
    new["sofa_liver"] = _points_high_is_bad(frame["Bilirubin_total"], [1.2, 2.0, 6.0, 12.0])
    new["sofa_cardio"] = _points_low_is_bad(frame["MAP"], [70])
    new["sofa_kidney"] = _points_high_is_bad(frame["Creatinine"], [1.2, 2.0, 3.5, 5.0])
    sofa = sum(new[c] for c in ["sofa_resp", "sofa_coag", "sofa_liver", "sofa_cardio", "sofa_kidney"])
    new["sofa_like"] = sofa
    lowest_24h = sofa.groupby(frame["Patient_ID"]).rolling(24, min_periods=1).min()
    lowest_24h = lowest_24h.reset_index(level=0, drop=True).sort_index()
    new["sofa_rise24"] = sofa - lowest_24h

    new_frame = pd.DataFrame(new, index=frame.index).replace([np.inf, -np.inf], np.nan)
    float_cols = new_frame.select_dtypes("float64").columns
    new_frame[float_cols] = new_frame[float_cols].astype("float32")
    return pd.concat([frame, new_frame], axis=1)


def features_last(rows, patient: dict, model_features: list[str]) -> pd.DataFrame:
    """Retourne les features modèle pour la dernière heure, sans utiliser le label."""
    art = get_art()
    if not rows:
        raise ValueError("Aucune mesure disponible pour ce patient")
    d = pd.DataFrame([dict(r) for r in rows])
    for col in VITALS_LABS:
        if col not in d.columns:
            d[col] = np.nan
    raw = d[["heure_icu"] + VITALS_LABS].astype(float).rename(columns={**DB2RAW, "heure_icu": "ICULOS"})
    raw["Patient_ID"] = "live"
    raw["Hospital"] = "live"
    raw["Age"] = float(patient["age"] if patient["age"] is not None else 60)
    raw["Gender"] = 1.0 if patient["sexe"] == "M" else 0.0
    raw["Unit1"] = np.nan if patient["unit1"] is None else float(patient["unit1"])
    raw["Unit2"] = np.nan if patient["unit2"] is None else float(patient["unit2"])
    raw["HospAdmTime"] = np.nan if patient["hosp_adm_time"] is None else float(patient["hosp_adm_time"])

    cleaned = clean(raw, art)
    dropped = [c for c in art["dropped_columns"] if c in cleaned.columns]
    if dropped:
        cleaned = cleaned.drop(columns=dropped)
    base = build_features(cleaned, art)
    complete = add_features(base)
    last = complete.iloc[[-1]].reindex(columns=model_features)
    return last.astype("float32")
