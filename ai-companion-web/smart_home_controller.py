"""Smart Home Controller - kirim command ke ESP32 via Firestore."""

import firebase_admin
from firebase_admin import credentials, firestore
from config import config

if not firebase_admin._apps:
    cred = credentials.Certificate(config.FIREBASE_CREDENTIALS)
    firebase_admin.initialize_app(cred)

db = firestore.client()


class SmartHomeController:
    def __init__(self):
        self.home_id = config.HOME_ID
        self.device_id = config.DEVICE_ID
        self.relay_map = config.RELAY_MAP
        self.scenes = config.SCENES

    def send_command(self, target: str, state: str, reason: str = "") -> dict:
        target_lower = target.lower().strip()
        relay_info = self.relay_map.get(target_lower)
        if not relay_info:
            for key, value in self.relay_map.items():
                if target_lower in key or key in target_lower:
                    relay_info = value
                    break

        if not relay_info:
            return {"success": False, "message": f"Perangkat '{target}' tidak ditemukan."}

        action = "on" if state.lower() in ["on", "nyala", "hidup", "1", "true"] else "off"
        _, ref = db.collection("commands").add({
            "homeId": self.home_id,
            "deviceId": self.device_id,
            "channelPin": relay_info["pin"],
            "channel": relay_info["channel"],
            "action": action,
            "source": "ai-companion-web",
            "reason": reason,
            "status": "pending",
            "createdAt": firestore.SERVER_TIMESTAMP,
        })

        status_text = "menyala 💡" if action == "on" else "mati 🌙"
        return {
            "success": True,
            "message": f"Lampu {target} → {status_text}",
            "command_id": ref.id,
            "action": action,
            "target": target,
        }

    def execute_scene(self, scene_id: str) -> dict:
        """Execute a predefined scene."""
        scene = self.scenes.get(scene_id)
        if not scene:
            return {"success": False, "message": f"Scene '{scene_id}' tidak ditemukan."}

        results = []
        for action in scene["actions"]:
            r = self.send_command(action["target"], action["state"],
                                 f"Scene: {scene['name']}")
            results.append(r)

        return {
            "success": True,
            "message": f"Scene '{scene['name']}' {scene['icon']} diaktifkan",
            "results": results,
        }

    def get_device_status(self) -> dict:
        try:
            doc = (db.collection("homes").document(self.home_id)
                   .collection("devices").document(self.device_id).get())
            if doc.exists:
                return doc.to_dict()
            return {"error": "Device not found"}
        except Exception as e:
            return {"error": str(e)}

    def get_all_relay_states(self) -> dict:
        status = self.get_device_status()
        if "error" in status:
            return status
        return status.get("relays", {})
