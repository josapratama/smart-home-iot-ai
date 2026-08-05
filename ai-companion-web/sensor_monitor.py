"""
Sensor Monitor - Reads sensor data from Firestore.
Provides context to AI about home conditions.
Handles missing indexes gracefully.
"""

from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from datetime import datetime, timezone, timedelta


class SensorMonitor:
    """Monitors sensor data and provides context to AI."""

    def __init__(self, db, home_id: str):
        self.db = db
        self.home_id = home_id

    def get_latest_energy(self) -> dict | None:
        """Get latest energy reading."""
        try:
            docs = (
                self.db.collection("sensor_readings")
                .where(filter=FieldFilter("homeId", "==", self.home_id))
                .where(filter=FieldFilter("type", "==", "energy"))
                .order_by("timestamp", direction=firestore.Query.DESCENDING)
                .limit(1)
                .stream()
            )
            for doc in docs:
                return doc.to_dict()
        except Exception:
            # Fallback: try without ordering (no composite index needed)
            try:
                docs = (
                    self.db.collection("sensor_readings")
                    .where(filter=FieldFilter("homeId", "==", self.home_id))
                    .where(filter=FieldFilter("type", "==", "energy"))
                    .limit(5)
                    .stream()
                )
                latest = None
                for doc in docs:
                    d = doc.to_dict()
                    if latest is None:
                        latest = d
                    else:
                        ts = d.get("timestamp")
                        lts = latest.get("timestamp")
                        if ts and lts and ts > lts:
                            latest = d
                return latest
            except Exception:
                pass
        return None

    def get_latest_gas(self) -> dict | None:
        """Get latest gas reading."""
        try:
            docs = (
                self.db.collection("sensor_readings")
                .where(filter=FieldFilter("homeId", "==", self.home_id))
                .where(filter=FieldFilter("type", "==", "gas"))
                .order_by("timestamp", direction=firestore.Query.DESCENDING)
                .limit(1)
                .stream()
            )
            for doc in docs:
                return doc.to_dict()
        except Exception:
            try:
                docs = (
                    self.db.collection("sensor_readings")
                    .where(filter=FieldFilter("homeId", "==", self.home_id))
                    .where(filter=FieldFilter("type", "==", "gas"))
                    .limit(5)
                    .stream()
                )
                latest = None
                for doc in docs:
                    d = doc.to_dict()
                    if latest is None:
                        latest = d
                    else:
                        ts = d.get("timestamp")
                        lts = latest.get("timestamp")
                        if ts and lts and ts > lts:
                            latest = d
                return latest
            except Exception:
                pass
        return None

    def get_latest_fire(self) -> dict | None:
        """Get latest fire sensor reading."""
        try:
            docs = (
                self.db.collection("sensor_readings")
                .where(filter=FieldFilter("homeId", "==", self.home_id))
                .where(filter=FieldFilter("type", "==", "fire"))
                .order_by("timestamp", direction=firestore.Query.DESCENDING)
                .limit(1)
                .stream()
            )
            for doc in docs:
                return doc.to_dict()
        except Exception:
            try:
                docs = (
                    self.db.collection("sensor_readings")
                    .where(filter=FieldFilter("homeId", "==", self.home_id))
                    .where(filter=FieldFilter("type", "==", "fire"))
                    .limit(5)
                    .stream()
                )
                latest = None
                for doc in docs:
                    d = doc.to_dict()
                    if latest is None:
                        latest = d
                    else:
                        ts = d.get("timestamp")
                        lts = latest.get("timestamp")
                        if ts and lts and ts > lts:
                            latest = d
                return latest
            except Exception:
                pass
        return None

    def get_active_alarms(self) -> list[dict]:
        """Get unresolved alarms."""
        try:
            docs = (
                self.db.collection("alarm_events")
                .where(filter=FieldFilter("homeId", "==", self.home_id))
                .where(filter=FieldFilter("isResolved", "==", False))
                .limit(5)
                .stream()
            )
            alarms = []
            for doc in docs:
                d = doc.to_dict()
                alarms.append({
                    "id": doc.id,
                    "type": d.get("type", "unknown"),
                    "severity": d.get("severity", "low"),
                    "message": d.get("message", ""),
                })
            return alarms
        except Exception:
            return []

    def get_energy_today(self) -> dict:
        """Get energy summary for today."""
        try:
            since = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0)
            docs = (
                self.db.collection("sensor_readings")
                .where(filter=FieldFilter("homeId", "==", self.home_id))
                .where(filter=FieldFilter("type", "==", "energy"))
                .where(filter=FieldFilter("timestamp", ">=", since))
                .stream()
            )
            total_power = 0
            count = 0
            max_power = 0
            for doc in docs:
                d = doc.to_dict()
                power = float(d.get("power", 0))
                total_power += power
                max_power = max(max_power, power)
                count += 1

            return {
                "avg_power": round(total_power / count, 2) if count > 0 else 0,
                "max_power": round(max_power, 2),
                "readings_count": count,
            }
        except Exception:
            return {"avg_power": 0, "max_power": 0, "readings_count": 0}

    def get_sensor_context(self) -> str:
        """Generate sensor context string for AI prompt."""
        lines = []

        energy = self.get_latest_energy()
        if energy:
            lines.append(
                f"⚡ Energi: {energy.get('power', 0):.1f}W, "
                f"{energy.get('voltage', 0):.0f}V, "
                f"{energy.get('current', 0):.2f}A"
            )

        gas = self.get_latest_gas()
        if gas:
            ppm = gas.get("gasPpm", 0)
            alert = "⚠️ ALERT!" if gas.get("gasAlert") else "Normal"
            lines.append(f"� Gas: {ppm} PPM ({alert})")

        fire = self.get_latest_fire()
        if fire:
            detected = "🚨 API TERDETEKSI!" if fire.get("flameDetected") else "Aman"
            lines.append(f"🔥 Api: {detected}")

        alarms = self.get_active_alarms()
        if alarms:
            lines.append(f"🚨 Alarm aktif: {len(alarms)} buah")
            for a in alarms[:2]:
                lines.append(f"   - [{a['severity']}] {a['message']}")

        if not lines:
            return "Sensor: Tidak ada data terbaru."

        return "DATA SENSOR TERKINI:\n" + "\n".join(lines)

    def get_sensor_summary_for_api(self) -> dict:
        """Get sensor data formatted for API response."""
        return {
            "energy": self.get_latest_energy(),
            "gas": self.get_latest_gas(),
            "fire": self.get_latest_fire(),
            "alarms": self.get_active_alarms(),
            "energy_today": self.get_energy_today(),
        }
