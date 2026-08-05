"""
Training model prediksi konsumsi energi.
Jalankan sekali sebelum predict.py.

Usage:
    python train.py --home_id <homeId>
"""

import argparse
import os
import joblib
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_percentage_error
from firebase_sync import get_energy_readings

MODELS_DIR = "models"
LAGS = 6


def create_features(df: pd.DataFrame) -> pd.DataFrame:
    """Buat fitur lag dari data time-series per jam."""
    # Resample per jam, ambil rata-rata arus
    df_hourly = df[["current"]].resample("h").mean()
    df_hourly["current"] = df_hourly["current"].ffill()

    for lag in range(1, LAGS + 1):
        df_hourly[f"lag_{lag}"] = df_hourly["current"].shift(lag)

    # Fitur waktu
    df_hourly["hour"]        = df_hourly.index.hour
    df_hourly["day_of_week"] = df_hourly.index.dayofweek

    return df_hourly.dropna()


def train(home_id: str) -> None:
    print(f"[Train] Mengambil data dari Firestore untuk home: {home_id}")
    df = get_energy_readings(home_id, days=30)

    if df.empty or len(df) < 50:
        print(f"[Train] Data tidak cukup ({len(df)} record). Minimal 50 record.")
        print("[Train] Pastikan sensor sudah mengirim data ke Firestore.")
        return

    df_feat = create_features(df)
    print(f"[Train] Fitur dibuat: {len(df_feat)} baris")

    feature_cols = [c for c in df_feat.columns if c != "current"]
    X = df_feat[feature_cols].values
    y = df_feat["current"].values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, shuffle=False
    )

    model = LinearRegression()
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    mape = mean_absolute_percentage_error(y_test, y_pred) * 100
    print(f"[Train] MAPE pada data uji: {mape:.2f}%")

    # Simpan model
    os.makedirs(MODELS_DIR, exist_ok=True)
    model_path = f"{MODELS_DIR}/energy_model_{home_id}.pkl"
    joblib.dump({
        "model":        model,
        "feature_cols": feature_cols,
        "mape":         mape,
        "home_id":      home_id,
    }, model_path)
    print(f"[Train] Model disimpan ke: {model_path}")
    print("[Train] Selesai! Sekarang jalankan predict.py")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train model prediksi energi")
    parser.add_argument("--home_id", required=True, help="ID rumah di Firestore")
    args = parser.parse_args()
    train(args.home_id)
