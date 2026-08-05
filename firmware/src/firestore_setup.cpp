#include <Arduino.h>
#include <HTTPClient.h>
#include "config.h"
#include "firestore.h"
#include "firestore_token.h"

#define PROJECT_ID  "smarthome-cfd3f"

// Daftar relay aktif — nama dari config.h, ubah di sana saja
struct RelayInfo { int pin; const char* name; };
static RelayInfo ACTIVE_RELAYS[] = {
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

static bool patchDoc(const String& path, const String& body) {
    HTTPClient http;
    String url = "https://firestore.googleapis.com/v1/projects/";
    url += PROJECT_ID;
    url += "/databases/(default)/documents/";
    url += path;
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " + g_idToken);
    http.setTimeout(8000);
    int code = http.PATCH(body);
    http.end();
    return (code == 200 || code == 201);
}

bool firestoreRegisterDevice(const char* homeId, const char* deviceId) {
    if (!ensureFirestoreToken()) return false;

    Serial.println("[Setup] Registering device...");

    String devicePath = "homes/";
    devicePath += homeId;
    devicePath += "/devices/";
    devicePath += deviceId;

    // isOnline di-set false dulu — akan di-update true oleh publishDeviceStatus
    // Ini mencegah device tampak Online jika ESP32 restart tanpa set offline
    String deviceBody = "{\"fields\":{"
        "\"name\":{\"stringValue\":\"" + String(DEVICE_DISPLAY_NAME) + "\"},"
        "\"type\":{\"stringValue\":\"relay\"},"
        "\"roomId\":{\"stringValue\":\"main\"},"
        "\"isOnline\":{\"booleanValue\":true},"
        "\"lastSeen\":{\"timestampValue\":\"" + getIsoTimestamp() + "\"}"
        "}}";

    if (!patchDoc(devicePath, deviceBody)) {
        Serial.println("[Setup] Device registration failed");
        return false;
    }

    // Register hanya relay yang aktif
    for (int i = 0; i < RELAY_COUNT; i++) {
        String channelId = "ch" + String(i + 1);
        String channelPath = devicePath + "/channels/" + channelId;
        String channelBody = "{\"fields\":{"
            "\"name\":{\"stringValue\":\"" + String(ACTIVE_RELAYS[i].name) + "\"},"
            "\"pin\":{\"integerValue\":" + String(ACTIVE_RELAYS[i].pin) + "},"
            "\"state\":{\"booleanValue\":false}"
            "}}";

        if (patchDoc(channelPath, channelBody)) {
            Serial.printf("[Setup] %s (pin %d) registered\n",
                ACTIVE_RELAYS[i].name, ACTIVE_RELAYS[i].pin);
        }
    }

    Serial.printf("[Setup] Done! %d relay(s) registered\n", RELAY_COUNT);
    return true;
}
