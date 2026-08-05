"""
Koneksi ke Firebase Firestore menggunakan Admin SDK.
Letakkan file serviceAccountKey.json di folder ai/
Download dari: Firebase Console > Project Settings > Service Accounts > Generate new private key
"""

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from datetime import datetime, timezone, timedelta
import pandas as pd

# Inisialisasi Firebase (hanya sekali)
if not firebase_admin._apps:
    cred = credentials.Certificate("smarthome-cfd3f-firebase-adminsdk-fbsvc-61519df010.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()


def get_energy_readings(home_id: str, days: int = 7) -> pd.DataFrame:
    """Ambil data sensor energi dari Firestore untuk N hari terakhir."""
    since = datetime.now(timezone.utc) - timedelta(days=days)

    docs = (
        db.collection("sensor_readings")
        .where(filter=FieldFilter("homeId", "==", home_id))
        .where(filter=FieldFilter("type", "==", "energy"))
        .where(filter=FieldFilter("timestamp", ">=", since))
        .order_by("timestamp")
        .stream()
    )

    records = []
    for doc in docs:
        d = doc.to_dict()
        records.append({
            "id":        doc.id,
            "timestamp": d["timestamp"],
            "current":   float(d.get("current", 0.0)),
            "voltage":   float(d.get("voltage", 0.0)),
            "power":     float(d.get("power", 0.0)),
            "energy":    float(d.get("energy", 0.0)),
        })

    if not records:
        return pd.DataFrame(columns=["id", "timestamp", "current"])

    df = pd.DataFrame(records)
    df["timestamp"] = pd.to_datetime(df["timestamp"], utc=True)
    df = df.set_index("timestamp").sort_index()
    return df


def save_prediction(home_id: str, device_id: str, predicted_kwh: float,
                    actual_kwh: float, mape: float) -> str:
    """Simpan hasil prediksi energi ke Firestore."""
    _, ref = db.collection("energy_predictions").add({
        "homeId":       home_id,
        "deviceId":     device_id,
        "predictedKwh": predicted_kwh,
        "actualKwh":    actual_kwh,
        "mape":         mape,
        "createdAt":    firestore.SERVER_TIMESTAMP,
    })
    return ref.id


def save_anomaly(home_id: str, prediction_id: str,
                 is_anomaly: bool, score: float) -> None:
    """Simpan hasil deteksi anomali ke Firestore."""
    db.collection("anomaly_results").add({
        "homeId":       home_id,
        "predictionId": prediction_id,
        "isAnomaly":    is_anomaly,
        "status":       "anomaly" if is_anomaly else "normal",
        "score":        score,
        "createdAt":    firestore.SERVER_TIMESTAMP,
    })


def trigger_alarm(home_id: str, message: str) -> None:
    """Buat alarm event di Firestore."""
    db.collection("alarm_events").add({
        "homeId":      home_id,
        "type":        "anomaly",
        "severity":    "medium",
        "message":     message,
        "isResolved":  False,
        "triggeredAt": firestore.SERVER_TIMESTAMP,
    })
