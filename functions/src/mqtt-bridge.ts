import { onRequest } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const HIVEMQ_HOST = process.env.HIVEMQ_HOST ?? "";
const HIVEMQ_USER = process.env.HIVEMQ_USER ?? "";
const HIVEMQ_PASSWORD = process.env.HIVEMQ_PASSWORD ?? "";
const GAS_THRESHOLD = 400;
const BIN_THRESHOLD = 80;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
let mqttClientInstance: any = null;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function getMqttClient(): any {
  if (mqttClientInstance) return mqttClientInstance;

  // Lazy import mqtt agar tidak diload saat module init
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const mqtt = require("mqtt");
  const db = getFirestore();

  mqttClientInstance = mqtt.connect(`mqtts://${HIVEMQ_HOST}:8883`, {
    username: HIVEMQ_USER,
    password: HIVEMQ_PASSWORD,
    clientId: `cloud-function-${Date.now()}`,
    rejectUnauthorized: false,
  });

  mqttClientInstance.on("connect", () => {
    console.log("[MQTT Bridge] Connected to HiveMQ");
    mqttClientInstance.subscribe("home/+/sensor/#");
    mqttClientInstance.subscribe("home/+/device/+/status");
  });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  mqttClientInstance.on("message", async (topic: string, payload: Buffer) => {
    try {
      const data = JSON.parse(payload.toString());
      const parts = topic.split("/");
      const homeId = parts[1];

      if (topic.includes("/sensor/energy")) {
        await db.collection("sensor_readings").add({
          homeId,
          type: "energy",
          voltage: data.voltage ?? 0,
          current: data.current ?? 0,
          power: data.power ?? 0,
          energy: data.energy ?? 0,
          frequency: data.frequency ?? 0,
          pf: data.pf ?? 0,
          timestamp: FieldValue.serverTimestamp(),
        });
      }

      if (topic.includes("/sensor/gas")) {
        const gasPpm: number = data.gasPpm ?? 0;
        const gasAlert: boolean = data.gasAlert ?? false;
        await db.collection("sensor_readings").add({
          homeId,
          type: "gas",
          gasPpm,
          gasAlert,
          timestamp: FieldValue.serverTimestamp(),
        });
        if (gasPpm > GAS_THRESHOLD || gasAlert) {
          await db.collection("alarm_events").add({
            homeId,
            type: "gas",
            severity: gasPpm > 700 ? "high" : "medium",
            message: `Kebocoran gas terdeteksi! Level: ${gasPpm} PPM`,
            isResolved: false,
            triggeredAt: FieldValue.serverTimestamp(),
          });
        }
      }

      if (topic.includes("/sensor/fire")) {
        const flameDetected: boolean = data.flameDetected ?? false;
        const flameAnalog: number = data.flameAnalog ?? 0;
        await db.collection("sensor_readings").add({
          homeId,
          type: "fire",
          flameDetected,
          flameAnalog,
          timestamp: FieldValue.serverTimestamp(),
        });
        if (flameDetected) {
          await db.collection("alarm_events").add({
            homeId,
            type: "fire",
            severity: "high",
            message: "Api terdeteksi! Segera periksa kondisi rumah.",
            isResolved: false,
            triggeredAt: FieldValue.serverTimestamp(),
          });
        }
      }

      if (topic.includes("/sensor/bin")) {
        const binLevel: number = data.binLevel ?? 0;
        await db.collection("sensor_readings").add({
          homeId,
          type: "bin",
          binLevel,
          timestamp: FieldValue.serverTimestamp(),
        });
        if (binLevel >= BIN_THRESHOLD) {
          await db.collection("alarm_events").add({
            homeId,
            type: "bin",
            severity: "low",
            message: `Tempat sampah hampir penuh! Level: ${binLevel}%`,
            isResolved: false,
            triggeredAt: FieldValue.serverTimestamp(),
          });
        }
      }

      if (topic.includes("/device/") && topic.includes("/status")) {
        const deviceId = parts[3];
        await db
          .collection("homes")
          .doc(homeId)
          .collection("devices")
          .doc(deviceId)
          .update({
            isOnline: data.online ?? false,
            lastSeen: FieldValue.serverTimestamp(),
          });
      }
    } catch (err) {
      console.error("[MQTT Bridge] Error:", err);
    }
  });

  return mqttClientInstance;
}

export const mqttBridge = onRequest((_req, res) => {
  getMqttClient();
  res.send("MQTT Bridge running");
});
