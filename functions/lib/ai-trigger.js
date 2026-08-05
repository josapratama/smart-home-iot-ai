"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var _a, _b, _c;
Object.defineProperty(exports, "__esModule", { value: true });
exports.onCommandCreate = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const mqtt = __importStar(require("mqtt"));
const HIVEMQ_HOST = (_a = process.env.HIVEMQ_HOST) !== null && _a !== void 0 ? _a : "";
const HIVEMQ_USER = (_b = process.env.HIVEMQ_USER) !== null && _b !== void 0 ? _b : "";
const HIVEMQ_PASSWORD = (_c = process.env.HIVEMQ_PASSWORD) !== null && _c !== void 0 ? _c : "";
// Trigger: setiap kali dokumen baru dibuat di /commands
exports.onCommandCreate = (0, firestore_1.onDocumentCreated)({ document: "commands/{commandId}", region: "us-central1" }, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
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
    await new Promise((resolve, reject) => {
        const client = mqtt.connect(`mqtts://${HIVEMQ_HOST}:8883`, {
            username: HIVEMQ_USER,
            password: HIVEMQ_PASSWORD,
            clientId: `cf-cmd-${Date.now()}`,
            rejectUnauthorized: false,
        });
        client.on("connect", () => {
            client.publish(topic, payload, { qos: 1 }, (err) => {
                client.end();
                if (err)
                    reject(err);
                else
                    resolve();
            });
        });
        client.on("error", reject);
    });
    await snap.ref.update({
        status: "sent",
        sentAt: firestore_2.FieldValue.serverTimestamp(),
    });
    console.log(`[Command] Published to ${topic}: ${payload}`);
});
//# sourceMappingURL=ai-trigger.js.map