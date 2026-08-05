"use strict";
var _a, _b, _c;
Object.defineProperty(exports, "__esModule", { value: true });
exports.mqttBridge = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const HIVEMQ_HOST = (_a = process.env.HIVEMQ_HOST) !== null && _a !== void 0 ? _a : "";
const HIVEMQ_USER = (_b = process.env.HIVEMQ_USER) !== null && _b !== void 0 ? _b : "";
const HIVEMQ_PASSWORD = (_c = process.env.HIVEMQ_PASSWORD) !== null && _c !== void 0 ? _c : "";
const GAS_THRESHOLD = 400;
const BIN_THRESHOLD = 80;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let mqttClientInstance = null;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function getMqttClient() {
    if (mqttClientInstance)
        return mqttClientInstance;
    // Lazy import mqtt agar tidak diload saat module init
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const mqtt = require("mqtt");
    const db = (0, firestore_1.getFirestore)();
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
    mqttClientInstance.on("message", async (topic, payload) => {
        var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m;
        try {
            const data = JSON.parse(payload.toString());
            const parts = topic.split("/");
            const homeId = parts[1];
            if (topic.includes("/sensor/energy")) {
                await db.collection("sensor_readings").add({
                    homeId,
                    type: "energy",
                    voltage: (_a = data.voltage) !== null && _a !== void 0 ? _a : 0,
                    current: (_b = data.current) !== null && _b !== void 0 ? _b : 0,
                    power: (_c = data.power) !== null && _c !== void 0 ? _c : 0,
                    energy: (_d = data.energy) !== null && _d !== void 0 ? _d : 0,
                    frequency: (_e = data.frequency) !== null && _e !== void 0 ? _e : 0,
                    pf: (_f = data.pf) !== null && _f !== void 0 ? _f : 0,
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                });
            }
            if (topic.includes("/sensor/gas")) {
                const gasPpm = (_g = data.gasPpm) !== null && _g !== void 0 ? _g : 0;
                const gasAlert = (_h = data.gasAlert) !== null && _h !== void 0 ? _h : false;
                await db.collection("sensor_readings").add({
                    homeId,
                    type: "gas",
                    gasPpm,
                    gasAlert,
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                });
                if (gasPpm > GAS_THRESHOLD || gasAlert) {
                    await db.collection("alarm_events").add({
                        homeId,
                        type: "gas",
                        severity: gasPpm > 700 ? "high" : "medium",
                        message: `Kebocoran gas terdeteksi! Level: ${gasPpm} PPM`,
                        isResolved: false,
                        triggeredAt: firestore_1.FieldValue.serverTimestamp(),
                    });
                }
            }
            if (topic.includes("/sensor/fire")) {
                const flameDetected = (_j = data.flameDetected) !== null && _j !== void 0 ? _j : false;
                const flameAnalog = (_k = data.flameAnalog) !== null && _k !== void 0 ? _k : 0;
                await db.collection("sensor_readings").add({
                    homeId,
                    type: "fire",
                    flameDetected,
                    flameAnalog,
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                });
                if (flameDetected) {
                    await db.collection("alarm_events").add({
                        homeId,
                        type: "fire",
                        severity: "high",
                        message: "Api terdeteksi! Segera periksa kondisi rumah.",
                        isResolved: false,
                        triggeredAt: firestore_1.FieldValue.serverTimestamp(),
                    });
                }
            }
            if (topic.includes("/sensor/bin")) {
                const binLevel = (_l = data.binLevel) !== null && _l !== void 0 ? _l : 0;
                await db.collection("sensor_readings").add({
                    homeId,
                    type: "bin",
                    binLevel,
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                });
                if (binLevel >= BIN_THRESHOLD) {
                    await db.collection("alarm_events").add({
                        homeId,
                        type: "bin",
                        severity: "low",
                        message: `Tempat sampah hampir penuh! Level: ${binLevel}%`,
                        isResolved: false,
                        triggeredAt: firestore_1.FieldValue.serverTimestamp(),
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
                    isOnline: (_m = data.online) !== null && _m !== void 0 ? _m : false,
                    lastSeen: firestore_1.FieldValue.serverTimestamp(),
                });
            }
        }
        catch (err) {
            console.error("[MQTT Bridge] Error:", err);
        }
    });
    return mqttClientInstance;
}
exports.mqttBridge = (0, https_1.onRequest)((_req, res) => {
    getMqttClient();
    res.send("MQTT Bridge running");
});
//# sourceMappingURL=mqtt-bridge.js.map