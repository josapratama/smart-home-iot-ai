"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onAlarmCreate = exports.onSensorReadingCreate = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
const GAS_THRESHOLD = 400;
const BIN_THRESHOLD = 80;
// Cooldown: jangan buat alarm baru untuk tipe yang sama dalam X menit
const ALARM_COOLDOWN_MINUTES = 10;
// ─── Helper: cek apakah alarm sejenis sudah ada dalam cooldown window ─────────
async function hasRecentAlarm(db, homeId, type) {
    const cutoff = firestore_2.Timestamp.fromDate(new Date(Date.now() - ALARM_COOLDOWN_MINUTES * 60 * 1000));
    const snap = await db
        .collection("alarm_events")
        .where("homeId", "==", homeId)
        .where("type", "==", type)
        .where("isResolved", "==", false)
        .where("triggeredAt", ">=", cutoff)
        .limit(1)
        .get();
    return !snap.empty;
}
// ─── Helper: kirim FCM ke semua member rumah ──────────────────────────────────
async function notifyHomeMembers(db, homeId, alarmId, alarmType, title, body) {
    var _a, _b, _c;
    const messaging = (0, messaging_1.getMessaging)();
    const homeSnap = await db.collection("homes").doc(homeId).get();
    if (!homeSnap.exists)
        return;
    const memberUids = (_b = (_a = homeSnap.data()) === null || _a === void 0 ? void 0 : _a.memberUids) !== null && _b !== void 0 ? _b : [];
    const tokens = [];
    for (const uid of memberUids) {
        const userSnap = await db.collection("users").doc(uid).get();
        const fcmToken = (_c = userSnap.data()) === null || _c === void 0 ? void 0 : _c.fcmToken;
        if (fcmToken)
            tokens.push(fcmToken);
    }
    if (tokens.length > 0) {
        const response = await messaging.sendEachForMulticast({
            tokens,
            notification: { title, body },
            data: { alarmId, type: alarmType, homeId },
            android: {
                priority: "high",
                notification: { channelId: "alarm_channel", sound: "alarm" },
            },
        });
        console.log(`[Alarm] FCM: ${response.successCount} success, ${response.failureCount} failed`);
    }
    await db.collection("notifications").add({
        homeId,
        title,
        body,
        type: "alarm",
        alarmId,
        isRead: false,
        createdAt: firestore_2.FieldValue.serverTimestamp(),
    });
}
// ─── Trigger 1: Firestore sensor_readings → buat alarm otomatis ───────────────
// Ini adalah trigger utama yang reliable — tidak bergantung MQTT
exports.onSensorReadingCreate = (0, firestore_1.onDocumentCreated)({ document: "sensor_readings/{readingId}", region: "us-central1" }, async (event) => {
    var _a, _b, _c, _d, _e, _f;
    const db = (0, firestore_2.getFirestore)();
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    const homeId = (_a = data.homeId) !== null && _a !== void 0 ? _a : "";
    const type = (_b = data.type) !== null && _b !== void 0 ? _b : "";
    if (!homeId)
        return;
    // ── Gas ──────────────────────────────────────────────────────────────────
    if (type === "gas") {
        const gasPpm = (_c = data.gasPpm) !== null && _c !== void 0 ? _c : 0;
        const gasAlert = (_d = data.gasAlert) !== null && _d !== void 0 ? _d : false;
        if (gasPpm > GAS_THRESHOLD || gasAlert) {
            // Cek cooldown — jangan spam alarm
            const alreadyAlarmed = await hasRecentAlarm(db, homeId, "gas");
            if (alreadyAlarmed) {
                console.log(`[Alarm] Gas alarm cooldown active for home ${homeId}`);
                return;
            }
            const severity = gasPpm > 700 ? "high" : "medium";
            const message = `Kebocoran gas terdeteksi! Level: ${gasPpm} PPM`;
            const title = "⚠️ Kebocoran Gas Terdeteksi!";
            const alarmRef = await db.collection("alarm_events").add({
                homeId,
                type: "gas",
                severity,
                message,
                isResolved: false,
                triggeredAt: firestore_2.FieldValue.serverTimestamp(),
            });
            console.log(`[Alarm] Gas alarm created: ${alarmRef.id} (${gasPpm} PPM)`);
            await notifyHomeMembers(db, homeId, alarmRef.id, "gas", title, message);
        }
    }
    // ── Fire ─────────────────────────────────────────────────────────────────
    if (type === "fire") {
        const flameDetected = (_e = data.flameDetected) !== null && _e !== void 0 ? _e : false;
        if (flameDetected) {
            const alreadyAlarmed = await hasRecentAlarm(db, homeId, "fire");
            if (alreadyAlarmed) {
                console.log(`[Alarm] Fire alarm cooldown active for home ${homeId}`);
                return;
            }
            const message = "Api terdeteksi! Segera periksa kondisi rumah.";
            const title = "🔥 Bahaya Api Terdeteksi!";
            const alarmRef = await db.collection("alarm_events").add({
                homeId,
                type: "fire",
                severity: "high",
                message,
                isResolved: false,
                triggeredAt: firestore_2.FieldValue.serverTimestamp(),
            });
            console.log(`[Alarm] Fire alarm created: ${alarmRef.id}`);
            await notifyHomeMembers(db, homeId, alarmRef.id, "fire", title, message);
        }
    }
    // ── Bin ──────────────────────────────────────────────────────────────────
    if (type === "bin") {
        const binLevel = (_f = data.binLevel) !== null && _f !== void 0 ? _f : 0;
        if (binLevel >= BIN_THRESHOLD) {
            const alreadyAlarmed = await hasRecentAlarm(db, homeId, "bin");
            if (alreadyAlarmed) {
                console.log(`[Alarm] Bin alarm cooldown active for home ${homeId}`);
                return;
            }
            const message = `Tempat sampah hampir penuh! Level: ${binLevel}%`;
            const title = "🗑️ Tempat Sampah Penuh!";
            const alarmRef = await db.collection("alarm_events").add({
                homeId,
                type: "bin",
                severity: "low",
                message,
                isResolved: false,
                triggeredAt: firestore_2.FieldValue.serverTimestamp(),
            });
            console.log(`[Alarm] Bin alarm created: ${alarmRef.id} (${binLevel}%)`);
            await notifyHomeMembers(db, homeId, alarmRef.id, "bin", title, message);
        }
    }
});
// ─── Trigger 2: alarm_events baru → kirim FCM (untuk alarm dari sumber lain) ──
// Ini handle alarm yang dibuat dari luar onSensorReadingCreate (misal manual/AI)
exports.onAlarmCreate = (0, firestore_1.onDocumentCreated)({ document: "alarm_events/{alarmId}", region: "us-central1" }, async (event) => {
    var _a;
    const db = (0, firestore_2.getFirestore)();
    const snap = event.data;
    if (!snap)
        return;
    const alarm = snap.data();
    const homeId = alarm.homeId;
    const alarmId = event.params.alarmId;
    // Jika alarm dibuat oleh onSensorReadingCreate, FCM sudah dikirim di sana
    // Cek flag untuk hindari double notif
    if (alarm._notified === true)
        return;
    console.log(`[Alarm] External alarm for home ${homeId}: ${alarm.type}`);
    const titleMap = {
        fire: "🔥 Bahaya Api Terdeteksi!",
        gas: "⚠️ Kebocoran Gas Terdeteksi!",
        bin: "🗑️ Tempat Sampah Penuh!",
        anomaly: "⚠️ Anomali Terdeteksi!",
    };
    const title = (_a = titleMap[alarm.type]) !== null && _a !== void 0 ? _a : "⚠️ Peringatan!";
    await notifyHomeMembers(db, homeId, alarmId, alarm.type, title, alarm.message);
});
//# sourceMappingURL=alarm.js.map