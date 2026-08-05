"""
Generate data dummy untuk testing pipeline AI (train + predict).

Mode:
  1. --mode offline  : Test pipeline lokal tanpa Firebase (default, cepat)
  2. --mode firebase : Upload data dummy ke Firestore lalu test pipeline

Usage:
    python generate_dummy_data.py                        # offline test
    python generate_dummy_data.py --mode firebase --home_id rumah_test_01
"""

import argparse
import os
import sys
import numpy as np
import pandas as pd
import joblib
from datetime import datetime, timezone, timedelta
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_percentage_error

# ─── Konfigurasi ────────────────────────────────────────────────────────────
MODELS_DIR        = "models"
LAGS              = 6
ANOMALY_THRESHOLD = 0.30   # 30% deviasi = anomali
DAYS              = 30     # jumlah hari data dummy
READINGS_PER_HOUR = 6      # 1 data tiap 10 menit


# ─── 1. Generator Data Dummy ─────────────────────────────────────────────────

def generate_dummy_readings(days: int = DAYS) -> pd.DataFrame:
    """
    Buat data sensor energi realistis:
    - Pola harian: konsumsi tinggi pagi (07-09) & malam (18-22)
    - Noise acak ±10%
    - Beberapa spike anomali (~3% data)
    """
    now   = datetime.now(timezone.utc)
    start = now - timedelta(days=days)

    # Buat timestamp setiap 10 menit
    timestamps = pd.date_range(start=start, end=now, freq="10min", tz="UTC")
    n          = len(timestamps)

    records = []
    rng     = np.random.default_rng(seed=42)

    for ts in timestamps:
        hour = ts.hour

        # Pola konsumsi per jam (Ampere)
        if   7  <= hour <= 9:   base_current = 4.5   # pagi sibuk
        elif 12 <= hour <= 13:  base_current = 3.8   # siang
        elif 18 <= hour <= 22:  base_current = 5.2   # malam sibuk
        elif 0  <= hour <= 5:   base_current = 1.2   # dini hari
        else:                   base_current = 2.5   # normal

        # Tambah noise ±10%
        noise   = rng.uniform(-0.10, 0.10)
        current = base_current * (1 + noise)

        # Spike anomali ~3% data
        if rng.random() < 0.03:
            current *= rng.uniform(1.5, 2.5)

        voltage = rng.uniform(218.0, 222.0)
        power   = current * voltage
        energy  = power / 1000 * (10 / 60)  # kWh per 10 menit

        records.append({
            "timestamp": ts,
            "current":   round(current, 3),
            "voltage":   round(voltage, 2),
            "power":     round(power, 2),
            "energy":    round(energy, 5),
        })

    df = pd.DataFrame(records)
    df = df.set_index("timestamp").sort_index()
    print(f"[Dummy] Data dibuat: {len(df)} record ({days} hari, setiap 10 menit)")
    return df


# ─── 2. Pipeline Offline (tanpa Firebase) ────────────────────────────────────

def create_features(df: pd.DataFrame) -> pd.DataFrame:
    """Sama persis dengan logika di train.py."""
    df_hourly = df[["current"]].resample("h").mean()
    df_hourly["current"] = df_hourly["current"].ffill()

    for lag in range(1, LAGS + 1):
        df_hourly[f"lag_{lag}"] = df_hourly["current"].shift(lag)

    df_hourly["hour"]        = df_hourly.index.hour
    df_hourly["day_of_week"] = df_hourly.index.dayofweek

    return df_hourly.dropna()


def run_offline_test(home_id: str = "dummy_home") -> None:
    print("\n" + "="*60)
    print("  MODE OFFLINE — Test Pipeline Lokal (tanpa Firebase)")
    print("="*60)

    # ── Step 1: Generate data ──
    print("\n[Step 1] Generate data dummy...")
    df = generate_dummy_readings(days=DAYS)
    print(f"         Rentang: {df.index[0]} → {df.index[-1]}")
    print(f"         Statistik current (A):")
    print(f"           Min  : {df['current'].min():.3f}")
    print(f"           Max  : {df['current'].max():.3f}")
    print(f"           Mean : {df['current'].mean():.3f}")
    print(f"           Std  : {df['current'].std():.3f}")

    # ── Step 2: Train ──
    print("\n[Step 2] Training model...")
    df_feat = create_features(df)
    print(f"         Fitur dibuat: {len(df_feat)} baris (hourly)")

    feature_cols = [c for c in df_feat.columns if c != "current"]
    X = df_feat[feature_cols].values
    y = df_feat["current"].values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, shuffle=False
    )
    print(f"         Train: {len(X_train)} | Test: {len(X_test)}")

    model = LinearRegression()
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    mape   = mean_absolute_percentage_error(y_test, y_pred) * 100
    print(f"         MAPE pada data uji: {mape:.2f}%")

    # Simpan model
    os.makedirs(MODELS_DIR, exist_ok=True)
    model_path = f"{MODELS_DIR}/energy_model_{home_id}.pkl"
    joblib.dump({
        "model":        model,
        "feature_cols": feature_cols,
        "mape":         mape,
        "home_id":      home_id,
    }, model_path)
    print(f"         Model disimpan: {model_path}")

    # ── Step 3: Predict ──
    print("\n[Step 3] Menjalankan prediksi...")
    hourly = df[["current"]].resample("h").mean()
    hourly["current"] = hourly["current"].ffill()

    now      = datetime.now(timezone.utc)
    features = {}
    for lag in range(1, LAGS + 1):
        features[f"lag_{lag}"] = float(hourly["current"].iloc[-(lag + 1)])
    features["hour"]        = now.hour
    features["day_of_week"] = now.weekday()

    X_pred    = np.array([[features[c] for c in feature_cols]])
    predicted = float(model.predict(X_pred)[0])
    actual    = float(hourly["current"].iloc[-1])
    mape_pt   = abs(actual - predicted) / (actual + 1e-9) * 100
    deviation = abs(actual - predicted) / (predicted + 1e-9)
    is_anomaly = deviation > ANOMALY_THRESHOLD

    print(f"         Prediksi : {predicted:.3f} A")
    print(f"         Aktual   : {actual:.3f} A")
    print(f"         MAPE     : {mape_pt:.1f}%")
    print(f"         Deviasi  : {deviation*100:.1f}%")

    # ── Step 4: Hasil ──
    print("\n[Step 4] Hasil deteksi anomali:")
    if is_anomaly:
        print(f"         ⚠️  ANOMALI terdeteksi!")
        print(f"         Aktual {actual:.2f}A vs Prediksi {predicted:.2f}A "
              f"(deviasi {deviation*100:.0f}%)")
    else:
        print(f"         ✅ Konsumsi energi NORMAL")

    # ── Step 5: Simulasi beberapa titik prediksi ──
    print("\n[Step 5] Simulasi 5 prediksi terakhir (per jam):")
    print(f"         {'Jam':<6} {'Aktual':>10} {'Prediksi':>10} {'Deviasi':>10} {'Status':>10}")
    print(f"         {'-'*50}")

    for i in range(5, 0, -1):
        idx = -(i + 1)
        feats = {}
        for lag in range(1, LAGS + 1):
            lag_idx = idx - lag
            if abs(lag_idx) <= len(hourly):
                feats[f"lag_{lag}"] = float(hourly["current"].iloc[lag_idx])
            else:
                feats[f"lag_{lag}"] = float(hourly["current"].mean())
        ts_sim = hourly.index[idx] if abs(idx) <= len(hourly) else now
        feats["hour"]        = ts_sim.hour
        feats["day_of_week"] = ts_sim.dayofweek

        X_sim   = np.array([[feats[c] for c in feature_cols]])
        pred_v  = float(model.predict(X_sim)[0])
        act_v   = float(hourly["current"].iloc[idx])
        dev_v   = abs(act_v - pred_v) / (pred_v + 1e-9)
        status  = "⚠️ ANOMALI" if dev_v > ANOMALY_THRESHOLD else "✅ Normal"
        jam_str = ts_sim.strftime("%H:%M")

        print(f"         {jam_str:<6} {act_v:>10.3f} {pred_v:>10.3f} "
              f"{dev_v*100:>9.1f}% {status:>10}")

    print("\n" + "="*60)
    print("  ✅ Pipeline berjalan NORMAL — semua step berhasil")
    print("="*60 + "\n")


# ─── 3. Pipeline Firebase (upload + test nyata) ───────────────────────────────

def run_firebase_test(home_id: str) -> None:
    print("\n" + "="*60)
    print("  MODE FIREBASE — Upload dummy data ke Firestore")
    print("="*60)

    try:
        from firebase_sync import get_energy_readings, save_prediction, save_anomaly, trigger_alarm
        import firebase_admin
        from firebase_admin import firestore as fs
    except ImportError as e:
        print(f"[Error] Import gagal: {e}")
        print("        Pastikan firebase-admin sudah terinstall: pip install firebase-admin")
        sys.exit(1)

    db = fs.client()

    # ── Upload data dummy ──
    print(f"\n[Firebase] Mengupload data dummy untuk home: {home_id}")
    df = generate_dummy_readings(days=30)

    batch_size = 400  # Firestore batch limit 500
    records    = df.reset_index().to_dict("records")
    total      = len(records)
    uploaded   = 0

    print(f"[Firebase] Total record: {total} (batch {batch_size})")

    for i in range(0, total, batch_size):
        batch = db.batch()
        chunk = records[i : i + batch_size]
        for rec in chunk:
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
        uploaded += len(chunk)
        print(f"[Firebase] Upload: {uploaded}/{total} record...")

    print(f"[Firebase] ✅ Upload selesai: {uploaded} record")

    # ── Jalankan train.py dan predict.py asli ──
    print("\n[Firebase] Menjalankan train.py...")
    from train import train
    train(home_id)

    print("\n[Firebase] Menjalankan predict.py...")
    from predict import run_prediction
    run_prediction(home_id)

    print("\n[Firebase] ✅ Test Firebase selesai!")


# ─── Main ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate dummy data & test pipeline AI")
    parser.add_argument(
        "--mode",
        choices=["offline", "firebase"],
        default="offline",
        help="offline = test lokal tanpa Firebase (default) | firebase = upload ke Firestore",
    )
    parser.add_argument(
        "--home_id",
        default="dummy_home_01",
        help="ID rumah (default: dummy_home_01)",
    )
    args = parser.parse_args()

    if args.mode == "offline":
        run_offline_test(home_id=args.home_id)
    else:
        run_firebase_test(home_id=args.home_id)
