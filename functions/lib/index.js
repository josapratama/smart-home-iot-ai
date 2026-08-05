"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onCommandCreate = exports.onSensorReadingCreate = exports.onAlarmCreate = exports.mqttBridge = void 0;
const app_1 = require("firebase-admin/app");
(0, app_1.initializeApp)();
// Re-export semua functions
var mqtt_bridge_1 = require("./mqtt-bridge");
Object.defineProperty(exports, "mqttBridge", { enumerable: true, get: function () { return mqtt_bridge_1.mqttBridge; } });
var alarm_1 = require("./alarm");
Object.defineProperty(exports, "onAlarmCreate", { enumerable: true, get: function () { return alarm_1.onAlarmCreate; } });
Object.defineProperty(exports, "onSensorReadingCreate", { enumerable: true, get: function () { return alarm_1.onSensorReadingCreate; } });
var ai_trigger_1 = require("./ai-trigger");
Object.defineProperty(exports, "onCommandCreate", { enumerable: true, get: function () { return ai_trigger_1.onCommandCreate; } });
//# sourceMappingURL=index.js.map