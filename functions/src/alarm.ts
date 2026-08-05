import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

const GAS_THRESHOLD = 400;
const BIN_THRESHOLD = 80;
// Cooldown: jangan buat alarm baru untuk tipe yang sama dalam X menit
const ALARM_COOLDOWN_MINUTES = 10;

// ─── Helper: cek apakah alarm sejenis sudah ada dalam cooldown window ─────────

async function hasRecentAlarm(
  db: FirebaseFirestore.Firestore,
  homeId: string,
  type: string,
): Promise<boolean> {
  const cutoff = Timestamp.fromDate(
    new Date(Date.now() - ALARM_COOLDOWN_MINUTES * 60 * 1000),
  );
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

async function notifyHomeMembers(
  db: FirebaseFirestore.Firestore,
  homeId: string,
  alarmId: string,
  alarmType: string,
  title: string,
  body: string,
): Promise<void> {
  const messaging = getMessaging();

  const homeSnap = await db.collection("homes").doc(homeId).get();
  if (!homeSnap.exists) return;

  const memberUids: string[] = homeSnap.data()?.memberUids ?? [];
  const tokens: string[] = [];

  for (const uid of memberUids) {
    const userSnap = await db.collection("users").doc(uid).get();
    const fcmToken: string | undefined = userSnap.data()?.fcmToken;
    if (fcmToken) tokens.push(fcmToken);
  }

  if (tokens.length > 0) {
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: { alarmId, type: alarmType, homeId },
      android: {
        priority: "high" as const,
        notification: { channelId: "alarm_channel", sound: "alarm" },
      },
    });
    console.log(
      `[Alarm] FCM: ${response.successCount} success, ${response.failureCount} failed`,
    );
  }

  await db.collection("notifications").add({
    homeId,
    title,
    body,
    type: "alarm",
    alarmId,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

// ─── Trigger 1: Firestore sensor_readings → buat alarm otomatis ───────────────
// Ini adalah trigger utama yang reliable — tidak bergantung MQTT

export const onSensorReadingCreate = onDocumentCreated(
  { document: "sensor_readings/{readingId}", region: "us-central1" },
  async (event) => {
    const db = getFirestore();
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const homeId: string = data.homeId ?? "";
    const type: string = data.type ?? "";

    if (!homeId) return;

    // ── Gas ──────────────────────────────────────────────────────────────────
    if (type === "gas") {
      const gasPpm: number = data.gasPpm ?? 0;
      const gasAlert: boolean = data.gasAlert ?? false;

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
          triggeredAt: FieldValue.serverTimestamp(),
        });

        console.log(
          `[Alarm] Gas alarm created: ${alarmRef.id} (${gasPpm} PPM)`,
        );
        await notifyHomeMembers(db, homeId, alarmRef.id, "gas", title, message);
      }
    }

    // ── Fire ─────────────────────────────────────────────────────────────────
    if (type === "fire") {
      const flameDetected: boolean = data.flameDetected ?? false;

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
          triggeredAt: FieldValue.serverTimestamp(),
        });

        console.log(`[Alarm] Fire alarm created: ${alarmRef.id}`);
        await notifyHomeMembers(
          db,
          homeId,
          alarmRef.id,
          "fire",
          title,
          message,
        );
      }
    }

    // ── Bin ──────────────────────────────────────────────────────────────────
    if (type === "bin") {
      const binLevel: number = data.binLevel ?? 0;

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
          triggeredAt: FieldValue.serverTimestamp(),
        });

        console.log(`[Alarm] Bin alarm created: ${alarmRef.id} (${binLevel}%)`);
        await notifyHomeMembers(db, homeId, alarmRef.id, "bin", title, message);
      }
    }
  },
);

// ─── Trigger 2: alarm_events baru → kirim FCM (untuk alarm dari sumber lain) ──
// Ini handle alarm yang dibuat dari luar onSensorReadingCreate (misal manual/AI)

export const onAlarmCreate = onDocumentCreated(
  { document: "alarm_events/{alarmId}", region: "us-central1" },
  async (event) => {
    const db = getFirestore();
    const snap = event.data;
    if (!snap) return;

    const alarm = snap.data();
    const homeId: string = alarm.homeId;
    const alarmId: string = event.params.alarmId;

    // Jika alarm dibuat oleh onSensorReadingCreate, FCM sudah dikirim di sana
    // Cek flag untuk hindari double notif
    if (alarm._notified === true) return;

    console.log(`[Alarm] External alarm for home ${homeId}: ${alarm.type}`);

    const titleMap: Record<string, string> = {
      fire: "🔥 Bahaya Api Terdeteksi!",
      gas: "⚠️ Kebocoran Gas Terdeteksi!",
      bin: "🗑️ Tempat Sampah Penuh!",
      anomaly: "⚠️ Anomali Terdeteksi!",
    };
    const title = titleMap[alarm.type as string] ?? "⚠️ Peringatan!";

    await notifyHomeMembers(
      db,
      homeId,
      alarmId,
      alarm.type as string,
      title,
      alarm.message as string,
    );
  },
);
