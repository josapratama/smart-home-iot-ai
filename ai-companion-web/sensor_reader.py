"""
Sensor Reader - Reads smart home sensor data from Firestore.
Provides context to AI about home conditions.
"""

from datetime import datetime, timezone, timedelta


class SensorReader:
    """Reads sensor data from Firestore for AI context."""

    def __init__(self, db, home_id: str):
        self.db = db
        self.home_id = home_id

    def get_latest_energy(self) -> dict | None:
        """Get latest energy reading."""
        docs = (
            self.db.collection("sensor_readings")
            .where("homeId", "==", self.home_id)
            .where("type", "==", "energy")
            .order_by("timestamp", direction="DESCENDING")
            .limit(1)
            .stream()
        )
        for doc in docs:
            return doc.to_dict()
        return None

    def get_latest_gas(self) -> dict | None:
        """Get latest gas reading."""
        docs = (
            self.db.collection("sensor_readings")
            .where("homeId", "==", self.home_id)
            .where("type", "==", "gas")
            .order_by("timestamp", direction="DESCENDING")
            .limit(1)
            .stream()
        )
        for doc in docs:
            return doc.to_dict()
        return None

    def get_latest_fire(self) -> dict | None:
        """Get latest fire sensor reading."""
        docs = (
            self.db.collection("sensor_readings")
            .where("homeId", "==", self.home_id)
            .where("type", "==", "fire")
            .order_by("timestamp", direction="DESCENDING")
            .limit(1)
            .stream()
        )
        for doc in docs:
            return doc.to_dict()
        return None

    def get_active_alarms(self) -> list[dict]:
        """Get unresolved alarms."""
        docs = (
            self.db.collection("alarm_events")
            .where("homeId", "==", self.home_id)
            .where("isResolved", "==", False)
            .order_by("triggeredAt", direction="DESCENDING")
            .limit(5)
            .stream()
        )
        alarms = []
        for doc in docs:
            alarms.append(doc.to_dict())
        return alarms

    def get_energy_summary(self, hours: int = 24) -> dict:
        """Get energy usage summary for last N hours."""
        since = datetime.now(timezone.utc) - timedelta(hours=hours)
        docs = (
            self.db.collection("sensor_readings")
            .where("homeId", "==", self.home_id)
            .where("type", "==", "energy")
            .where("timestamp", ">=", since)
            .order_by("timestamp")
            .stream()
        )
        readings = []
        for doc in docs:
            readings.append(doc.to_dict())

        if not readings:
            return {"total_kwh": 0, "avg_power": 0, "max_power": 0, "count": 0}

        powers = [r.get("power", 0) for r in readings]
        energies = [r.get("energy", 0) for r in readings]

        return {
            "total_kwh": max(energies) - min(energies) if energies else 0,
            "avg_power": sum(powers) / len(powers) if powers else 0,
            "max_power": max(powers) if powers else 0,
            "count": len(readings),
        }

    def get_sensor_context_for_ai(self) -> str:
        """Generate sensor context string for AI system prompt."""
        lines = ["DATA SENSOR RUMAH SAAT INI:"]

        energy = self.get_latest_energy()
        if energy:
            lines.append(
                f"- Listrik: {energy.get('power', 0):.1f}W, "
                f"{energy.get('voltage', 0):.0f}V, "
                f"{energy.get('current', 0):.2f}A, "
                f"Total: {energy.get('energy', 0):.2f} kWh"
            )

        gas = self.get_latest_gas()
        if gas:
            ppm = gas.get("gasPpm", 0)
            alert = "⚠️ ALERT!" if gas.get("gasAlert") else "Normal"
            lines.append(f"- Gas: {ppm} PPM ({alert})")

        fire = self.get_latest_fire()
        if fire:
            detected = "🔥 API TERDETEKSI!" if fire.get("flameDetected") else "Aman"
            lines.append(f"- Api: {detected}")

        alarms = self.get_active_alarms()
        if alarms:
            lines.append(f"- ⚠️ Ada {len(alarms)} alarm aktif:")
            for a in alarms[:3]:
                lines.append(f"  • [{a.get('type')}] {a.get('message', '')}")

        if len(lines) == 1:
            lines.append("- Tidak ada data sensor terbaru.")

        return "\n".join(lines)
