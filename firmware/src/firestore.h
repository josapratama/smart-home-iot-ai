#pragma once
#include <Arduino.h>

void   firestoreInit();
bool   ensureFirestoreToken();

// ── Timestamp helper ──────────────────────────────────────────────────────────
// Menghasilkan ISO 8601 timestamp dari millis() sebagai fallback
// Format: "1970-01-01T00:00:00Z" (epoch-based, akurat setelah NTP sync)
String getIsoTimestamp();

// ── Sensor readings ───────────────────────────────────────────────────────────

bool firestoreAddSensorReading(
    const char* homeId,
    float voltage, float current, float power,
    float energy, float frequency, float pf
);

bool firestoreAddGasReading(
    const char* homeId, int ppm, bool alert
);

bool firestoreAddFlameReading(
    const char* homeId, bool detected, int analog
);

bool firestoreAddBinReading(
    const char* homeId, int levelPercent
);

// ── Alarm event ───────────────────────────────────────────────────────────────

bool firestoreAddAlarm(
    const char* homeId,
    const char* type,      // "gas" | "fire"
    const char* severity,  // "high" | "medium"
    const char* message
);

// ── Device ────────────────────────────────────────────────────────────────────

bool firestoreUpdateDeviceStatus(
    const char* homeId, const char* deviceId, bool isOnline
);

bool firestoreUpdateChannelState(
    const char* homeId, const char* deviceId, int pin, bool state
);

bool firestoreRegisterDevice(
    const char* homeId, const char* deviceId
);
