import os
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.api as sm
from linearmodels.panel import PanelOLS, RandomEffects
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sqlalchemy import create_engine


OUTPUT_DIR = Path("outputs")
OUTPUT_DIR.mkdir(exist_ok=True)


def get_engine():
    dialect = os.getenv("DB_DIALECT", "mysql+mysqldb")
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "3306")
    db = os.getenv("DB_NAME", "public_education")
    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")

    if not user or not password:
        raise ValueError("Set DB_USER and DB_PASSWORD environment variables.")

    conn = f"{dialect}://{user}:{password}@{host}:{port}/{db}"
    return create_engine(conn)


def load_data(engine):
    query = """
    SELECT
        Cod_IES,
        NU_ANO_CENSO,
        taxa_evasao,
        cat_uni_priv,
        cat_cu_priv,
        igc_continuo,
        peso_ead,
        peso_apoio_social,
        peso_ativ_extracur,
        matriculas,
        cat_priv
    FROM VW_IES_AGRUPADO_TCC2
    WHERE NU_ANO_CENSO IN (2021, 2022)
      AND igc_continuo IS NOT NULL
      AND matriculas > 100
      AND cat_priv = 1
    """

    df = pd.read_sql(query, engine)
    if df.empty:
        raise ValueError("Query returned no data. Check filters and source tables.")

    df["Cod_IES"] = df["Cod_IES"].astype("category").cat.codes
    df["NU_ANO_CENSO"] = pd.to_numeric(df["NU_ANO_CENSO"], errors="coerce").astype(int)
    return df


def transform(df):
    data = df.copy()
    data.fillna(0, inplace=True)

    data["peso_ead"] *= 100
    data["peso_apoio_social"] *= 100
    data["peso_ativ_extracur"] *= 100

    data["taxa_evasao"] = np.sqrt(np.clip(data["taxa_evasao"], a_min=0, a_max=None))
    data["igc_continuo"] = np.power(data["igc_continuo"], 3)

    panel = data.set_index(["Cod_IES", "NU_ANO_CENSO"])
    return panel


def run_panel_models(df_panel):
    y = df_panel["taxa_evasao"]
    X = sm.add_constant(df_panel.drop(columns=["taxa_evasao"]).astype(float))

    fe = PanelOLS(y, X, check_rank=False).fit(cov_type="robust")
    re = RandomEffects(y, X, check_rank=False).fit(cov_type="robust")

    return {
        "model": ["Panel_FE", "Panel_RE"],
        "metric": ["rsquared", "rsquared"],
        "value": [float(fe.rsquared), float(re.rsquared)],
    }


def run_rf(df_panel):
    y = df_panel["taxa_evasao"].values
    X = df_panel.drop(columns=["taxa_evasao"]).astype(float).values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.3, random_state=42
    )

    rf = RandomForestRegressor(
        n_estimators=300,
        max_depth=30,
        random_state=42,
        n_jobs=-1,
    )
    rf.fit(X_train, y_train)

    preds = rf.predict(X_test)
    return {
        "model": ["RandomForest", "RandomForest"],
        "metric": ["mse", "r2"],
        "value": [float(mean_squared_error(y_test, preds)), float(r2_score(y_test, preds))],
    }


def main():
    engine = get_engine()
    df = load_data(engine)
    df_panel = transform(df)

    panel_results = pd.DataFrame(run_panel_models(df_panel))
    rf_results = pd.DataFrame(run_rf(df_panel))

    out = pd.concat([panel_results, rf_results], ignore_index=True)
    out.to_csv(OUTPUT_DIR / "model_comparison.csv", index=False)

    print("Done. Results written to outputs/model_comparison.csv")


if __name__ == "__main__":
    main()
