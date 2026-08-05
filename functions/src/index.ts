import { initializeApp } from "firebase-admin/app";

initializeApp();

// Re-export semua functions
export { mqttBridge } from "./mqtt-bridge";
export { onAlarmCreate, onSensorReadingCreate } from "./alarm";
export { onCommandCreate } from "./ai-trigger";
