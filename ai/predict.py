"""
Prediksi konsumsi energi + deteksi anomali.
Jalankan setelah train.py.

Usage:
    python predict.py --home_id <homeId>
    python predict.py --home_id <homeId> --schedule   # jalan terus setiap jam
"""

import argparse
import joblib
import numpy as np
import schedule
import time
from datetime import datetime, timezone
from firebase_sync import (
    get_energy_readings,
    save_prediction,
    save_anomaly,
    trigger_alarm,
)

MODELS_DIR        = "models"
ANOMALY_THRESHOLD = 0.30   # 30% deviasi dari prediksi = anomali
LAGS              = 6


def load_model(home_id: str) -> dict:
    path = f"{MODELS_DIR}/energy_model_{home_id}.pkl"
    return joblib.load(path)


def run_prediction(home_id: str) -> None:
    now = datetime.now(timezone.utc)
    print(f"\n[Predict] {now.strftime('%Y-%m-%d %H:%M:%S')} UTC — home: {home_id}")

    # Load model
    try:
        bundle = load_model(home_id)
    except FileNotFoundError:
        print(f"[Predict] Model tidak ditemukan untuk home: {home_id}")
        print("[Predict] Jalankan: python train.py --home_id", home_id)
        return

    model        = bundle["model"]
    feature_cols = bundle["feature_cols"]

    # Ambil data terbaru (1 hari untuk fitur lag)
    df = get_energy_readings(home_id, days=1)
    if df.empty or len(df) < LAGS + 1:
        print(f"[Predict] Data tidak cukup ({len(df)} record). Minimal {LAGS + 1}.")
        return

    # Resample per jam
    hourly = df[["current"]].resample("h").mean()
    hourly["current"] = hourly["current"].ffill()

    if len(hourly) < LAGS + 1:
        print(f"[Predict] Data per jam tidak cukup ({len(hourly)} jam).")
        return

    # Buat fitur dari data terbaru
    features = {}
    for lag in range(1, LAGS + 1):
        features[f"lag_{lag}"] = float(hourly["current"].iloc[-(lag + 1)])
    features["hour"]        = now.hour
    features["day_of_week"] = now.weekday()

    # Prediksi
    X         = np.array([[features[c] for c in feature_cols]])
    predicted = float(model.predict(X)[0])
    actual    = float(hourly["current"].iloc[-1])

    # MAPE satu titik
    mape = abs(actual - predicted) / (actual + 1e-9) * 100

    print(f"[Predict] Prediksi : {predicted:.3f} A")
    print(f"[Predict] Aktual   : {actual:.3f} A")
    print(f"[Predict] MAPE     : {mape:.1f}%")

    # Simpan prediksi ke Firestore
    pred_id = save_prediction(
        home_id       = home_id,
        device_id     = f"{home_id}_esp32",
        predicted_kwh = predicted,
        actual_kwh    = actual,
        mape          = mape,
    )
    print(f"[Predict] Prediksi disimpan: {pred_id}")

    # Deteksi anomali
    deviation  = abs(actual - predicted) / (predicted + 1e-9)
    is_anomaly = deviation > ANOMALY_THRESHOLD

    save_anomaly(
        home_id       = home_id,
        prediction_id = pred_id,
        is_anomaly    = is_anomaly,
        score         = float(deviation),
    )

    if is_anomaly:
        msg = (
            f"Anomali konsumsi energi terdeteksi! "
            f"Aktual {actual:.2f}A vs Prediksi {predicted:.2f}A "
            f"(deviasi {deviation * 100:.0f}%)"
        )
        print(f"[Predict] ⚠️  ANOMALI: {msg}")
        trigger_alarm(home_id, msg)
    else:
        print("[Predict] ✅ Konsumsi energi normal.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Prediksi energi + deteksi anomali")
    parser.add_argument("--home_id", required=True, help="ID rumah di Firestore")
    parser.add_argument(
        "--schedule",
        action="store_true",
        help="Jalankan otomatis setiap jam",
    )
    args = parser.parse_args()

    if args.schedule:
        print(f"[Predict] Mode terjadwal: setiap jam untuk home: {args.home_id}")
        run_prediction(args.home_id)          # Jalankan sekali langsung
        schedule.every().hour.do(run_prediction, home_id=args.home_id)
        while True:
            schedule.run_pending()
            time.sleep(60)
    else:
        run_prediction(args.home_id)
