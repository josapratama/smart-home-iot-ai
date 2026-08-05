#include <Arduino.h>
#include <ArduinoJson.h>
#include "config.h"
#include "sensors.h"
#include "mqtt_client.h"
#include "firestore.h"

// ─── Init ─────────────────────────────────────────────────────────────────────

void initSensors() {
#ifdef ENABLE_PZEM
    pzemInit(PZEM_SERIAL, PZEM_RX_PIN, PZEM_TX_PIN);
    Serial.println("[Sensor] PZEM-004T enabled");
#endif

#ifdef ENABLE_MQ2
    #ifdef MQ2_USE_ANALOG_MODE
        Serial.printf("[Sensor] MQ-2 enabled — ANALOG mode (A=%d, threshold=%d PPM)\n",
            PIN_MQ2_ANALOG, GAS_THRESHOLD_PPM);
    #else
        pinMode(PIN_MQ2_DIGITAL, INPUT);
        Serial.printf("[Sensor] MQ-2 enabled — DIGITAL mode (A=%d D=%d)\n",
            PIN_MQ2_ANALOG, PIN_MQ2_DIGITAL);
    #endif
    // Beri waktu heater MQ-2 warm-up agar tidak spike arus saat WiFi connect
    Serial.println("[Sensor] MQ-2 warming up (2s)...");
    delay(2000);
#endif

#ifdef ENABLE_FLAME
    #ifdef FLAME_USE_ANALOG_MODE
        Serial.printf("[Sensor] Flame enabled — ANALOG mode (A=%d, threshold<%d)\n",
            PIN_FLAME_ANALOG, FLAME_ANALOG_THRESHOLD);
    #else
        pinMode(PIN_FLAME_DIGITAL, INPUT);
        Serial.printf("[Sensor] Flame enabled — DIGITAL mode (A=%d D=%d)\n",
            PIN_FLAME_ANALOG, PIN_FLAME_DIGITAL);
    #endif
#endif

#ifdef ENABLE_ULTRASONIC
    pinMode(PIN_TRIG, OUTPUT);
    pinMode(PIN_ECHO, INPUT);
    Serial.printf("[Sensor] Ultrasonic enabled (TRIG=%d ECHO=%d)\n",
        PIN_TRIG, PIN_ECHO);
#endif

#ifdef ENABLE_BUZZER
    pinMode(PIN_BUZZER, OUTPUT);
    digitalWrite(PIN_BUZZER, LOW);
    Serial.printf("[Sensor] Buzzer enabled (pin=%d)\n", PIN_BUZZER);
#endif
}

// ─── MQ-2 ─────────────────────────────────────────────────────────────────────

#ifdef ENABLE_MQ2
Mq2Data readMq2() {
    Mq2Data d;
    int raw = analogRead(PIN_MQ2_ANALOG);
    // Konversi sederhana ADC → PPM (kalibrasi sesuai datasheet MQ-2)
    d.ppm = map(raw, 0, 4095, 0, 1000);

#ifdef MQ2_USE_ANALOG_MODE
    // Mode analog: alert berdasarkan threshold software (tidak pakai pin DO)
    d.digitalAlert = (d.ppm > GAS_THRESHOLD_PPM);
#else
    // Mode digital: alert dari pin DO modul (diatur lewat potensiometer)
    d.digitalAlert = (digitalRead(PIN_MQ2_DIGITAL) == LOW);
#endif
    return d;
}
#endif

// ─── Flame ────────────────────────────────────────────────────────────────────

#ifdef ENABLE_FLAME
FlameData readFlame() {
    FlameData d;
    d.analog = analogRead(PIN_FLAME_ANALOG);

#ifdef FLAME_USE_ANALOG_MODE
    // Mode analog: api terdeteksi jika nilai ADC di bawah threshold (sensor IR aktif rendah)
    d.detected = (d.analog < FLAME_ANALOG_THRESHOLD);
#else
    // Mode digital: deteksi dari pin DO modul (diatur lewat potensiometer), active LOW
    d.detected = (digitalRead(PIN_FLAME_DIGITAL) == LOW);
#endif
    return d;
}
#endif

// ─── Ultrasonic ───────────────────────────────────────────────────────────────

#ifdef ENABLE_ULTRASONIC
// Kembalikan jarak dalam cm, atau -1.0 jika timeout / tidak valid
float readDistanceCm() {
    digitalWrite(PIN_TRIG, LOW);
    delayMicroseconds(2);
    digitalWrite(PIN_TRIG, HIGH);
    delayMicroseconds(10);
    digitalWrite(PIN_TRIG, LOW);

    long duration = pulseIn(PIN_ECHO, HIGH, 30000); // timeout 30ms = ~510cm

    if (duration == 0) {
        // Timeout: tidak ada echo — sensor tidak terhubung atau jarak terlalu jauh
        return -1.0f;
    }

    float dist = duration * 0.034f / 2.0f;

    // Validasi range: HC-SR04 efektif 2cm–400cm
    if (dist < 2.0f || dist > 400.0f) {
        return -1.0f;
    }

    return dist;
}

int binLevelPercent() {
    float dist   = readDistanceCm();
    float height = (float)BIN_HEIGHT_CM;

    if (dist < 0.0f) {
        // Sensor error / timeout → anggap kosong (0%) bukan penuh (100%)
        Serial.println("[Ultrasonic] WARNING: Tidak ada echo — cek kabel/posisi sensor");
        return 0;
    }

    // Jika jarak lebih besar dari tinggi wadah, artinya benar-benar kosong
    if (dist >= height) return 0;

    int level = (int)(((height - dist) / height) * 100.0f);
    return constrain(level, 0, 100);
}
#endif

// ─── Buzzer helper ────────────────────────────────────────────────────────────

#ifdef ENABLE_BUZZER
static void buzzAlert(int times = 3, int ms = 200) {
    for (int i = 0; i < times; i++) {
        digitalWrite(PIN_BUZZER, HIGH);
        delay(ms);
        digitalWrite(PIN_BUZZER, LOW);
        delay(ms);
    }
}
#endif

// ─── Alarm cooldown ───────────────────────────────────────────────────────────
// Cegah spam alarm — kirim maksimal 1 alarm per tipe setiap 10 menit

#define ALARM_COOLDOWN_MS (10UL * 60 * 1000)  // 10 menit

static unsigned long lastAlarmTime_gas  = 0;
static unsigned long lastAlarmTime_fire = 0;
static unsigned long lastAlarmTime_bin  = 0;

static bool canSendAlarm(unsigned long& lastTime) {
    unsigned long now = millis();
    if (now - lastTime >= ALARM_COOLDOWN_MS) {
        lastTime = now;
        return true;
    }
    return false;
}

// ─── Publish semua sensor ─────────────────────────────────────────────────────

void publishSensorData() {
    bool alarmTriggered = false;

    // ── PZEM ──────────────────────────────────────────────────────────────────
#ifdef ENABLE_PZEM
    {
        PzemData d = pzemRead();
        if (!d.valid) {
            Serial.println("[PZEM] Invalid — publishing zeros");
            d = {0, 0, 0, 0, 0, 0, false};
        } else {
            Serial.printf("[PZEM] V=%.1fV I=%.3fA P=%.1fW E=%.3fkWh F=%.1fHz PF=%.2f\n",
                d.voltage, d.current, d.power, d.energy, d.frequency, d.pf);
        }

        StaticJsonDocument<128> doc;
        doc["voltage"]   = d.voltage;
        doc["current"]   = d.current;
        doc["power"]     = d.power;
        doc["energy"]    = d.energy;
        doc["frequency"] = d.frequency;
        doc["pf"]        = d.pf;
        char payload[128];
        serializeJson(doc, payload);
        mqttPublish(TOPIC_SENSOR_ENERGY, payload);

        firestoreAddSensorReading(HOME_ID,
            d.voltage, d.current, d.power,
            d.energy, d.frequency, d.pf);
    }
#endif

    // ── MQ-2 ──────────────────────────────────────────────────────────────────
#ifdef ENABLE_MQ2
    {
        Mq2Data d = readMq2();
        Serial.printf("[MQ2] PPM=%d Alert=%s\n",
            d.ppm, d.digitalAlert ? "YES" : "no");

        StaticJsonDocument<64> doc;
        doc["gasPpm"]    = d.ppm;
        doc["gasAlert"]  = d.digitalAlert;
        char payload[64];
        serializeJson(doc, payload);
        mqttPublish(TOPIC_SENSOR_GAS, payload);

        // Simpan ke Firestore
        firestoreAddGasReading(HOME_ID, d.ppm, d.digitalAlert);

        if (d.ppm > GAS_THRESHOLD_PPM || d.digitalAlert) {
            alarmTriggered = true;
            if (canSendAlarm(lastAlarmTime_gas)) {
                char msg[80];
                snprintf(msg, sizeof(msg),
                    "Kebocoran gas terdeteksi! Level: %d PPM", d.ppm);
                firestoreAddAlarm(HOME_ID, "gas",
                    d.ppm > 700 ? "high" : "medium", msg);
            }
#ifdef ENABLE_BUZZER
            buzzAlert(5, 150);
#endif
        }
    }
#endif

    // ── Flame ─────────────────────────────────────────────────────────────────
#ifdef ENABLE_FLAME
    {
        FlameData d = readFlame();
        Serial.printf("[Flame] Analog=%d Detected=%s\n",
            d.analog, d.detected ? "YES" : "no");

        StaticJsonDocument<64> doc;
        doc["flameDetected"] = d.detected;
        doc["flameAnalog"]   = d.analog;
        char payload[64];
        serializeJson(doc, payload);
        mqttPublish(TOPIC_SENSOR_FIRE, payload);

        // Simpan ke Firestore
        firestoreAddFlameReading(HOME_ID, d.detected, d.analog);

        if (d.detected) {
            alarmTriggered = true;
            if (canSendAlarm(lastAlarmTime_fire)) {
                firestoreAddAlarm(HOME_ID, "fire", "high",
                    "Api terdeteksi! Segera periksa kondisi rumah.");
            }
#ifdef ENABLE_BUZZER
            buzzAlert(10, 100);
#endif
        }
    }
#endif

    // ── Ultrasonic ────────────────────────────────────────────────────────────
#ifdef ENABLE_ULTRASONIC
    {
        int level = binLevelPercent();
        Serial.printf("[Ultrasonic] Bin level=%d%%\n", level);

        StaticJsonDocument<32> doc;
        doc["binLevel"] = level;
        char payload[32];
        serializeJson(doc, payload);
        mqttPublish(TOPIC_SENSOR_BIN, payload);

        // Simpan ke Firestore
        firestoreAddBinReading(HOME_ID, level);

        // Alarm jika sampah hampir penuh
        if (level >= BIN_FULL_PERCENT) {
            alarmTriggered = true;
            if (canSendAlarm(lastAlarmTime_bin)) {
                char msg[60];
                snprintf(msg, sizeof(msg),
                    "Tempat sampah hampir penuh! Level: %d%%", level);
                firestoreAddAlarm(HOME_ID, "bin", "low", msg);
            }
        }
    }
#endif

    (void)alarmTriggered; // suppress unused warning jika buzzer disabled
}
