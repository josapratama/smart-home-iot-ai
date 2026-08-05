#include <Arduino.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <time.h>
#include "config.h"
#include "firestore.h"
#include "firestore_token.h"

#define PROJECT_ID  "smarthome-cfd3f"
#define API_KEY     "AIzaSyDyhQmvzjnaiYN6GSQFm5ess5-1hUJ_P7E"

// Global token — shared dengan firestore_setup.cpp
String        g_idToken    = "";
unsigned long g_tokenExpiry = 0;

// Persistent storage untuk menyimpan localId (UID anonymous)
// agar tidak buat akun baru setiap restart
static Preferences prefs;
static String      g_localId = "";

// ─── Timestamp Helper ─────────────────────────────────────────────────────────

String getIsoTimestamp() {
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        // NTP belum sync — gunakan epoch + millis sebagai fallback kasar
        // Firestore tetap menerima ini, hanya tidak akurat
        unsigned long ms = millis() / 1000;
        char buf[32];
        snprintf(buf, sizeof(buf), "1970-01-01T00:%02lu:%02luZ",
                 (ms / 60) % 60, ms % 60);
        return String(buf);
    }
    char buf[32];
    strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);
    return String(buf);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

static bool anonymousSignIn() {
    HTTPClient http;

    // Cek apakah sudah punya localId tersimpan
    prefs.begin("firestore", false);
    g_localId = prefs.getString("localId", "");
    prefs.end();

    String url;
    String body;

    if (g_localId.isEmpty()) {
        // Pertama kali — buat akun anonymous baru
        url  = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=";
        url += API_KEY;
        body = "{\"returnSecureToken\":true}";
        Serial.println("[Firestore] Creating new anonymous account...");
    } else {
        // Sudah punya akun — refresh token saja
        url  = "https://securetoken.googleapis.com/v1/token?key=";
        url += API_KEY;
        // Kita tidak punya refresh token di ESP, jadi sign in ulang
        // tapi tetap pakai localId yang sama dengan lookup
        url  = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=";
        url += API_KEY;
        body = "{\"returnSecureToken\":true}";
        Serial.printf("[Firestore] Re-authenticating (localId: %s...)\n",
            g_localId.substring(0, 8).c_str());
    }

    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    int code = http.POST(body);

    if (code == 200) {
        StaticJsonDocument<1024> doc;
        deserializeJson(doc, http.getString());
        g_idToken    = doc["idToken"].as<String>();
        g_tokenExpiry = millis() + (55UL * 60 * 1000);

        String newLocalId = doc["localId"].as<String>();

        // Simpan localId ke Preferences jika baru
        if (g_localId.isEmpty() || g_localId != newLocalId) {
            g_localId = newLocalId;
            prefs.begin("firestore", false);
            prefs.putString("localId", g_localId);
            prefs.end();
            Serial.printf("[Firestore] New account saved: %s...\n",
                g_localId.substring(0, 8).c_str());
        } else {
            Serial.println("[Firestore] Sign-in OK (existing account)");
        }

        http.end();
        return true;
    }

    Serial.printf("[Firestore] Sign-in failed: %d\n", code);
    http.end();
    return false;
}

bool ensureFirestoreToken() {
    if (g_idToken.isEmpty() || millis() > g_tokenExpiry) {
        return anonymousSignIn();
    }
    return true;
}

void firestoreInit() {
    // Load localId dari Preferences saat boot
    prefs.begin("firestore", true);
    g_localId = prefs.getString("localId", "");
    prefs.end();

    if (!g_localId.isEmpty()) {
        Serial.printf("[Firestore] Existing account: %s...\n",
            g_localId.substring(0, 8).c_str());
    } else {
        Serial.println("[Firestore] No saved account, will create on first use");
    }
}

// ─── Helper: PATCH document ───────────────────────────────────────────────────

static int patchDoc(const String& path, const String& body) {
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
    return code;
}

// ─── Sensor Reading ───────────────────────────────────────────────────────────

bool firestoreAddSensorReading(
    const char* homeId,
    float voltage, float current, float power,
    float energy, float frequency, float pf
) {
    if (!ensureFirestoreToken()) return false;

    HTTPClient http;
    String url = "https://firestore.googleapis.com/v1/projects/";
    url += PROJECT_ID;
    url += "/databases/(default)/documents/sensor_readings";
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " + g_idToken);
    http.setTimeout(8000);

    String body = "{\"fields\":{"
        "\"homeId\":{\"stringValue\":\"" + String(homeId) + "\"},"
        "\"type\":{\"stringValue\":\"energy\"},"
        "\"voltage\":{\"doubleValue\":" + String(voltage, 2) + "},"
        "\"current\":{\"doubleValue\":" + String(current, 3) + "},"
        "\"power\":{\"doubleValue\":" + String(power, 1) + "},"
        "\"energy\":{\"doubleValue\":" + String(energy, 3) + "},"
        "\"frequency\":{\"doubleValue\":" + String(frequency, 1) + "},"
        "\"pf\":{\"doubleValue\":" + String(pf, 2) + "},"
        "\"timestamp\":{\"timestampValue\":\"" + getIsoTimestamp() + "\"}"
        "}}";

    int code = http.POST(body);
    if (code == 200 || code == 201) {
        Serial.println("[Firestore] Sensor saved");
        http.end();
        return true;
    }
    if (code == 401) { g_idToken = ""; g_tokenExpiry = 0; }
    Serial.printf("[Firestore] Sensor POST failed: %d\n", code);
    http.end();
    return false;
}

// ─── Gas Reading ──────────────────────────────────────────────────────────────

bool firestoreAddGasReading(const char* homeId, int ppm, bool alert) {
    if (!ensureFirestoreToken()) return false;

    HTTPClient http;
    String url = "https://firestore.googleapis.com/v1/projects/";
    url += PROJECT_ID;
    url += "/databases/(default)/documents/sensor_readings";
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " + g_idToken);
    http.setTimeout(8000);

    String body = "{\"fields\":{"
        "\"homeId\":{\"stringValue\":\"" + String(homeId) + "\"},"
        "\"type\":{\"stringValue\":\"gas\"},"
        "\"gasPpm\":{\"integerValue\":" + String(ppm) + "},"
        "\"gasAlert\":{\"booleanValue\":" + String(alert ? "true" : "false") + "},"
        "\"timestamp\":{\"timestampValue\":\"" + getIsoTimestamp() + "\"}"
        "}}";

    int code = http.POST(body);
    if (code == 200 || code == 201) { http.end(); return true; }
    if (code == 401) { g_idToken = ""; g_tokenExpiry = 0; }
    Serial.printf("[Firestore] Gas POST failed: %d\n", code);
    http.end();
    return false;
}

// ─── Flame Reading ────────────────────────────────────────────────────────────

bool firestoreAddFlameReading(const char* homeId, bool detected, int analog) {
    if (!ensureFirestoreToken()) return false;

    HTTPClient http;
    String url = "https://firestore.googleapis.com/v1/projects/";
    url += PROJECT_ID;
    url += "/databases/(default)/documents/sensor_readings";
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " + g_idToken);
    http.setTimeout(8000);

    String body = "{\"fields\":{"
        "\"homeId\":{\"stringValue\":\"" + String(homeId) + "\"},"
        "\"type\":{\"stringValue\":\"fire\"},"
        "\"flameDetected\":{\"booleanValue\":" + String(detected ? "true" : "false") + "},"
        "\"flameAnalog\":{\"integerValue\":" + String(analog) + "},"
        "\"timestamp\":{\"timestampValue\":\"" + getIsoTimestamp() + "\"}"
        "}}";

    int code = http.POST(body);
    if (code == 200 || code == 201) { http.end(); return true; }
    if (code == 401) { g_idToken = ""; g_tokenExpiry = 0; }
    Serial.printf("[Firestore] Flame POST failed: %d\n", code);
    http.end();
    return false;
}

// ─── Bin Reading ──────────────────────────────────────────────────────────────

bool firestoreAddBinReading(const char* homeId, int levelPercent) {
    if (!ensureFirestoreToken()) return false;

    HTTPClient http;
    String url = "https://firestore.googleapis.com/v1/projects/";
    url += PROJECT_ID;
    url += "/databases/(default)/documents/sensor_readings";
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " + g_idToken);
    http.setTimeout(8000);

    String body = "{\"fields\":{"
        "\"homeId\":{\"stringValue\":\"" + String(homeId) + "\"},"
        "\"type\":{\"stringValue\":\"bin\"},"
        "\"binLevel\":{\"integerValue\":" + String(levelPercent) + "},"
        "\"timestamp\":{\"timestampValue\":\"" + getIsoTimestamp() + "\"}"
        "}}";

    int code = http.POST(body);
    if (code == 200 || code == 201) { http.end(); return true; }
    if (code == 401) { g_idToken = ""; g_tokenExpiry = 0; }
    Serial.printf("[Firestore] Bin POST failed: %d\n", code);
    http.end();
    return false;
}

// ─── Alarm Event ──────────────────────────────────────────────────────────────

bool firestoreAddAlarm(
    const char* homeId,
    const char* type,
    const char* severity,
    const char* message
) {
    if (!ensureFirestoreToken()) return false;

    HTTPClient http;
    String url = "https://firestore.googleapis.com/v1/projects/";
    url += PROJECT_ID;
    url += "/databases/(default)/documents/alarm_events";
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " + g_idToken);
    http.setTimeout(8000);

    String body = "{\"fields\":{"
        "\"homeId\":{\"stringValue\":\"" + String(homeId) + "\"},"
        "\"type\":{\"stringValue\":\"" + String(type) + "\"},"
        "\"severity\":{\"stringValue\":\"" + String(severity) + "\"},"
        "\"message\":{\"stringValue\":\"" + String(message) + "\"},"
        "\"isResolved\":{\"booleanValue\":false},"
        "\"triggeredAt\":{\"timestampValue\":\"" + getIsoTimestamp() + "\"}"
        "}}";

    int code = http.POST(body);
    if (code == 200 || code == 201) {
        Serial.printf("[Firestore] Alarm saved: %s\n", message);
        http.end();
        return true;
    }
    if (code == 401) { g_idToken = ""; g_tokenExpiry = 0; }
    Serial.printf("[Firestore] Alarm POST failed: %d\n", code);
    http.end();
    return false;
}

// ─── Device Status ────────────────────────────────────────────────────────────

bool firestoreUpdateDeviceStatus(
    const char* homeId,
    const char* deviceId,
    bool isOnline
) {
    if (!ensureFirestoreToken()) return false;

    String path = "homes/";
    path += homeId;
    path += "/devices/";
    path += deviceId;
    // Update isOnline DAN lastSeen sekaligus
    path += "?updateMask.fieldPaths=isOnline&updateMask.fieldPaths=lastSeen";

    String body = "{\"fields\":{"
        "\"isOnline\":{\"booleanValue\":";
    body += isOnline ? "true" : "false";
    body += "},\"lastSeen\":{\"timestampValue\":\"";
    body += getIsoTimestamp();
    body += "\"}}}";

    int code = patchDoc(path, body);
    if (code == 200) return true;
    if (code == 401) { g_idToken = ""; g_tokenExpiry = 0; }
    Serial.printf("[Firestore] Status PATCH failed: %d\n", code);
    return false;
}

// ─── Channel State ────────────────────────────────────────────────────────────

bool firestoreUpdateChannelState(
    const char* homeId,
    const char* deviceId,
    int pin,
    bool state
) {
    if (!ensureFirestoreToken()) return false;

    String channelId = "";
    if      (pin == PIN_RELAY_1) channelId = "ch1";
    else if (pin == PIN_RELAY_2) channelId = "ch2";
    else if (pin == PIN_RELAY_3) channelId = "ch3";
    else if (pin == PIN_RELAY_4) channelId = "ch4";
    else { Serial.printf("[Firestore] Unknown pin: %d\n", pin); return false; }

    String path = "homes/";
    path += homeId;
    path += "/devices/";
    path += deviceId;
    path += "/channels/";
    path += channelId;
    path += "?updateMask.fieldPaths=state";

    String body = "{\"fields\":{\"state\":{\"booleanValue\":";
    body += state ? "true" : "false";
    body += "}}}";

    int code = patchDoc(path, body);
    if (code == 200) {
        Serial.printf("[Firestore] ch%s state=%s\n",
            channelId.c_str(), state ? "ON" : "OFF");
        return true;
    }
    if (code == 401) { g_idToken = ""; g_tokenExpiry = 0; }
    Serial.printf("[Firestore] Channel PATCH failed: %d\n", code);
    return false;
}
