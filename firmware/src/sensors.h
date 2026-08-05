#pragma once
#include "config.h"
#include "pzem.h"

// Inisialisasi semua sensor yang aktif
void initSensors();

// Baca dan publish semua sensor yang aktif ke MQTT + Firestore
void publishSensorData();

// ── Data struct per sensor ────────────────────────────────────────────────────

#ifdef ENABLE_MQ2
struct Mq2Data {
    int    ppm;          // estimasi PPM dari ADC
    bool   digitalAlert; // HIGH jika melewati threshold hardware
};
Mq2Data readMq2();
#endif

#ifdef ENABLE_FLAME
struct FlameData {
    int  analog;         // nilai ADC (0-4095), makin kecil makin terang
    bool detected;       // true jika digital output LOW (api terdeteksi)
};
FlameData readFlame();
#endif

#ifdef ENABLE_ULTRASONIC
float readDistanceCm();
int   binLevelPercent();
#endif
