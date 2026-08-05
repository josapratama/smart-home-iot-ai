#include <Arduino.h>
#include <ArduinoJson.h>
#include "config.h"
#include "actuators.h"
#include "mqtt_client.h"
#include "firestore.h"

// Build daftar relay yang aktif berdasarkan feature flags
struct RelayDef { int pin; const char* name; };

// Nama relay dari config.h — ubah di sana, tidak perlu edit file ini
static RelayDef ACTIVE_RELAYS[] = {
#ifdef ENABLE_RELAY_1
    {PIN_RELAY_1, RELAY_1_NAME},
#endif
#ifdef ENABLE_RELAY_2
    {PIN_RELAY_2, RELAY_2_NAME},
#endif
#ifdef ENABLE_RELAY_3
    {PIN_RELAY_3, RELAY_3_NAME},
#endif
#ifdef ENABLE_RELAY_4
    {PIN_RELAY_4, RELAY_4_NAME},
#endif
};

static const int RELAY_COUNT = sizeof(ACTIVE_RELAYS) / sizeof(ACTIVE_RELAYS[0]);

void initActuators() {
    for (int i = 0; i < RELAY_COUNT; i++) {
        pinMode(ACTIVE_RELAYS[i].pin, OUTPUT);
        digitalWrite(ACTIVE_RELAYS[i].pin, HIGH); // active LOW — OFF saat boot
        Serial.printf("[Relay] %s (pin %d) initialized (OFF)\n",
            ACTIVE_RELAYS[i].name, ACTIVE_RELAYS[i].pin);
    }
    if (RELAY_COUNT == 0) {
        Serial.println("[Relay] No relays enabled");
    }
}

void setRelay(int pin, bool state) {
    for (int i = 0; i < RELAY_COUNT; i++) {
        if (ACTIVE_RELAYS[i].pin == pin) {
            digitalWrite(pin, state ? LOW : HIGH);
            Serial.printf("[Relay] Pin %d -> %s\n", pin, state ? "ON" : "OFF");
            return;
        }
    }
    Serial.printf("[Relay] Invalid/disabled pin: %d\n", pin);
}

bool getRelayState(int pin) {
    return digitalRead(pin) == LOW;
}

void publishDeviceStatus(bool isOnline) {
    StaticJsonDocument<256> doc;
    doc["deviceId"] = DEVICE_ID;
    doc["online"]   = isOnline;
    doc["uptime"]   = millis() / 1000;

    JsonObject relays = doc.createNestedObject("relays");
    for (int i = 0; i < RELAY_COUNT; i++) {
        String key = "r" + String(i + 1);
        relays[key] = getRelayState(ACTIVE_RELAYS[i].pin);
    }

    char payload[256];
    serializeJson(doc, payload);
    mqttPublish(TOPIC_DEVICE_STATUS, payload, true);

    // Update lastSeen di Firestore agar Flutter bisa deteksi offline
    firestoreUpdateDeviceStatus(HOME_ID, DEVICE_ID, isOnline);
}
