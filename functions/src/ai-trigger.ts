import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import * as mqtt from "mqtt";

const HIVEMQ_HOST = process.env.HIVEMQ_HOST ?? "";
const HIVEMQ_USER = process.env.HIVEMQ_USER ?? "";
const HIVEMQ_PASSWORD = process.env.HIVEMQ_PASSWORD ?? "";

// Trigger: setiap kali dokumen baru dibuat di /commands
export const onCommandCreate = onDocumentCreated(
  { document: "commands/{commandId}", region: "us-central1" },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const command = snap.data();
    const { homeId, deviceId, channelPin, action } = command;
    const commandId = event.params.commandId;

    console.log(`[Command] ${action} pin ${channelPin} on device ${deviceId}`);

    const topic = `home/${homeId}/device/${deviceId}/command`;
    const payload = JSON.stringify({
      pin: channelPin,
      state: action === "on",
      commandId,
    });

    await new Promise<void>((resolve, reject) => {
      const client = mqtt.connect(`mqtts://${HIVEMQ_HOST}:8883`, {
        username: HIVEMQ_USER,
        password: HIVEMQ_PASSWORD,
        clientId: `cf-cmd-${Date.now()}`,
        rejectUnauthorized: false,
      });

      client.on("connect", () => {
        client.publish(topic, payload, { qos: 1 }, (err) => {
          client.end();
          if (err) reject(err);
          else resolve();
        });
      });

      client.on("error", reject);
    });

    await snap.ref.update({
      status: "sent",
      sentAt: FieldValue.serverTimestamp(),
    });

    console.log(`[Command] Published to ${topic}: ${payload}`);
  },
);
