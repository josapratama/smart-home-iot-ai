"""
Script all-in-one untuk:
1. Cek homeId yang ada di Firestore
2. Upload data dummy sensor ke Firestore
3. Train model
4. Predict & simpan ke energy_predictions + anomaly_results

Ini akan membuat status AI Prediction di dashboard berubah menjadi "Aktif".

Usage:
    python run_dummy_firebase.py                        # auto-detect homeId
    python run_dummy_firebase.py --home_id <homeId>    # pakai homeId manual
"""

import argparse
import sys
import os
import numpy as np
import pandas as pd
import joblib
from datetime import datetime, timezone, timedelta
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_percentage_error

# ─── Init Firebase ────────────────────────────────────────────────────────────
import firebase_admin
from firebase_admin import credentials, firestore as fs

if not firebase_admin._apps:
    cred_path = "smarthome-cfd3f-firebase-adminsdk-fbsvc-61519df010.json"
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = fs.client()

MODELS_DIR        = "models"
LAGS              = 6
ANOMALY_THRESHOLD = 0.30
DAYS              = 30


# ─── Step 0: Auto-detect homeId ───────────────────────────────────────────────

def get_existing_home_id() -> str | None:
    """Ambil homeId pertama yang ditemukan di koleksi /homes."""
    homes = db.collection("homes").limit(5).stream()
    for doc in homes:
        home_id = doc.id
        print(f"[Info] Ditemukan homeId di Firestore: {home_id}")
        return home_id
    return None


def get_home_id_from_users() -> str | None:
    """Ambil homeId dari profil user pertama."""
    users = db.collection("users").limit(5).stream()
    for doc in users:
        data = doc.to_dict()
        home_id = data.get("homeId") or data.get("home_id")
        if home_id:
            print(f"[Info] Ditemukan homeId dari users/{doc.id}: {home_id}")
            return home_id
    return None


# ─── Step 1: Generate dummy sensor data ───────────────────────────────────────

def generate_dummy_readings(days: int = DAYS) -> pd.DataFrame:
    now   = datetime.now(timezone.utc)
    start = now - timedelta(days=days)
    timestamps = pd.date_range(start=start, end=now, freq="10min", tz="UTC")

    records = []
    rng = np.random.default_rng(seed=42)

    for ts in timestamps:
        hour = ts.hour
        if   7  <= hour <= 9:   base = 4.5
        elif 12 <= hour <= 13:  base = 3.8
        elif 18 <= hour <= 22:  base = 5.2
        elif 0  <= hour <= 5:   base = 1.2
        else:                   base = 2.5

        noise   = rng.uniform(-0.10, 0.10)
        current = base * (1 + noise)
        if rng.random() < 0.03:
            current *= rng.uniform(1.5, 2.5)

        voltage = rng.uniform(218.0, 222.0)
        power   = current * voltage
        energy  = power / 1000 * (10 / 60)

        records.append({
            "timestamp": ts,
            "current":   round(current, 3),
            "voltage":   round(voltage, 2),
            "power":     round(power, 2),
            "energy":    round(energy, 5),
        })

    df = pd.DataFrame(records).set_index("timestamp").sort_index()
    print(f"[Step 1] Data dibuat: {len(df)} record ({days} hari)")
    return df


# ─── Step 2: Upload ke Firestore ──────────────────────────────────────────────

def upload_sensor_data(home_id: str, df: pd.DataFrame) -> None:
    # Cek apakah sudah ada data agar tidak double upload
    from google.cloud.firestore_v1.base_query import FieldFilter
    existing = (
        db.collection("sensor_readings")
        .where(filter=FieldFilter("homeId", "==", home_id))
        .where(filter=FieldFilter("type", "==", "energy"))
        .limit(1)
        .stream()
    )
    existing_list = list(existing)
    if existing_list:
        print(f"[Step 2] Data sensor sudah ada di Firestore untuk homeId={home_id}, skip upload.")
        return

    batch_size = 400
    records    = df.reset_index().to_dict("records")
    total      = len(records)
    uploaded   = 0
    print(f"[Step 2] Upload {total} record ke Firestore (batch {batch_size})...")

    for i in range(0, total, batch_size):
        batch = db.batch()
        for rec in records[i : i + batch_size]:
            ref = db.collection("sensor_readings").document()
            batch.set(ref, {
                "homeId":    home_id,
                "type":      "energy",
                "timestamp": rec["timestamp"],
                "current":   rec["current"],
                "voltage":   rec["voltage"],
                "power":     rec["power"],
                "energy":    rec["energy"],
            })
        batch.commit()
        uploaded += len(records[i : i + batch_size])
        pct = int(uploaded / total * 100)
        print(f"[Step 2]   Upload: {uploaded}/{total} ({pct}%)")

    print(f"[Step 2] ✅ Upload selesai: {uploaded} record")


# ─── Step 3: Train model ──────────────────────────────────────────────────────

def create_features(df: pd.DataFrame) -> pd.DataFrame:
    df_hourly = df[["current"]].resample("h").mean()
    df_hourly["current"] = df_hourly["current"].ffill()
    for lag in range(1, LAGS + 1):
        df_hourly[f"lag_{lag}"] = df_hourly["current"].shift(lag)
    df_hourly["hour"]        = df_hourly.index.hour
    df_hourly["day_of_week"] = df_hourly.index.dayofweek
    return df_hourly.dropna()


def train_model(home_id: str, df: pd.DataFrame):
    print(f"[Step 3] Training model untuk homeId={home_id}...")
    df_feat      = create_features(df)
    feature_cols = [c for c in df_feat.columns if c != "current"]
    X = df_feat[feature_cols].values
    y = df_feat["current"].values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, shuffle=False
    )
    model = LinearRegression()
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    mape   = mean_absolute_percentage_error(y_test, y_pred) * 100
    print(f"[Step 3]   MAPE data uji: {mape:.2f}%")

    os.makedirs(MODELS_DIR, exist_ok=True)
    model_path = f"{MODELS_DIR}/energy_model_{home_id}.pkl"
    bundle = {
        "model":        model,
        "feature_cols": feature_cols,
        "mape":         mape,
        "home_id":      home_id,
    }
    joblib.dump(bundle, model_path)
    print(f"[Step 3] ✅ Model disimpan: {model_path}")
    return bundle, df_feat


# ─── Step 4: Predict & simpan ke Firestore ────────────────────────────────────

def run_predict_and_save(home_id: str, bundle: dict, df: pd.DataFrame) -> None:
    print(f"[Step 4] Menjalankan prediksi untuk homeId={home_id}...")

    model        = bundle["model"]
    feature_cols = bundle["feature_cols"]

    hourly = df[["current"]].resample("h").mean()
    hourly["current"] = hourly["current"].ffill()

    now      = datetime.now(timezone.utc)
    features = {}
    for lag in range(1, LAGS + 1):
        features[f"lag_{lag}"] = float(hourly["current"].iloc[-(lag + 1)])
    features["hour"]        = now.hour
    features["day_of_week"] = now.weekday()

    X         = np.array([[features[c] for c in feature_cols]])
    predicted = float(model.predict(X)[0])
    actual    = float(hourly["current"].iloc[-1])
    mape      = abs(actual - predicted) / (actual + 1e-9) * 100
    deviation = abs(actual - predicted) / (predicted + 1e-9)
    is_anomaly = deviation > ANOMALY_THRESHOLD

    print(f"[Step 4]   Prediksi : {predicted:.3f} A")
    print(f"[Step 4]   Aktual   : {actual:.3f} A")
    print(f"[Step 4]   MAPE     : {mape:.1f}%")
    print(f"[Step 4]   Deviasi  : {deviation*100:.1f}%")

    # Simpan ke energy_predictions
    _, pred_ref = db.collection("energy_predictions").add({
        "homeId":       home_id,
        "deviceId":     f"{home_id}_esp32",
        "predictedKwh": predicted,
        "actualKwh":    actual,
        "mape":         mape,
        "createdAt":    fs.SERVER_TIMESTAMP,
    })
    pred_id = pred_ref.id
    print(f"[Step 4] ✅ Prediksi disimpan: energy_predictions/{pred_id}")

    # Simpan ke anomaly_results
    db.collection("anomaly_results").add({
        "homeId":       home_id,
        "predictionId": pred_id,
        "isAnomaly":    is_anomaly,
        "status":       "anomaly" if is_anomaly else "normal",
        "score":        float(deviation),
        "createdAt":    fs.SERVER_TIMESTAMP,
    })
    print(f"[Step 4] ✅ Anomali disimpan: {'ANOMALI' if is_anomaly else 'Normal'} (skor {deviation*100:.1f}%)")

    if is_anomaly:
        msg = (
            f"Anomali konsumsi energi terdeteksi! "
            f"Aktual {actual:.2f}A vs Prediksi {predicted:.2f}A "
            f"(deviasi {deviation*100:.0f}%)"
        )
        db.collection("alarm_events").add({
            "homeId":      home_id,
            "type":        "anomaly",
            "severity":    "medium",
            "message":     msg,
            "isResolved":  False,
            "triggeredAt": fs.SERVER_TIMESTAMP,
        })
        print(f"[Step 4] ⚠️  Alarm event dibuat.")


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Run full AI pipeline (dummy data → Firestore → AI Prediction aktif)"
    )
    parser.add_argument(
        "--home_id",
        default=None,
        help="ID rumah (auto-detect jika tidak diisi)",
    )
    args = parser.parse_args()

    print("\n" + "="*60)
    print("  SMART HOME — AI Pipeline dengan Data Dummy")
    print("="*60)

    # ── Tentukan home_id ──
    home_id = args.home_id
    if not home_id:
        home_id = get_home_id_from_users() or get_existing_home_id()

    if not home_id:
        print("\n[Error] Tidak ada homeId ditemukan di Firestore!")
        print("        Opsi 1: Buka app Android → buat/join rumah → coba lagi")
        print("        Opsi 2: Jalankan dengan --home_id <homeId> manual")
        sys.exit(1)

    print(f"\n[Info] Menggunakan homeId: {home_id}\n")

    # ── Jalankan pipeline ──
    df = generate_dummy_readings(days=DAYS)
    upload_sensor_data(home_id, df)
    bundle, _ = train_model(home_id, df)
    run_predict_and_save(home_id, bundle, df)

    print("\n" + "="*60)
    print("  ✅ SELESAI — Status AI Prediction di dashboard seharusnya")
    print("     berubah menjadi  ● Aktif")
    print("="*60 + "\n")


if __name__ == "__main__":
    main()
