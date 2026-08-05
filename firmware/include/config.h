#pragma once

// ── WiFi ──────────────────────────────────────────────────────────────────────
#define WIFI_SSID       "tselhome"
#define WIFI_PASSWORD   "admin2004"

// ── HiveMQ Cloud ──────────────────────────────────────────────────────────────
#define MQTT_HOST       "c23e14c17f1d483cada7eea56160ee75.s1.eu.hivemq.cloud"
#define MQTT_PORT       8883
#define MQTT_USER       "smarthome"
#define MQTT_PASSWORD   "Password123"
#define MQTT_CLIENT_ID  "esp32-smarthome-01"

// ── Home / Device ID ──────────────────────────────────────────────────────────
#define HOME_ID         "j2QdNiBNAKrbgYayYMia"
#define DEVICE_ID       "device_esp32_01"

// ── MQTT Topics ───────────────────────────────────────────────────────────────
#define TOPIC_SENSOR_ENERGY   "home/" HOME_ID "/sensor/energy"
#define TOPIC_SENSOR_GAS      "home/" HOME_ID "/sensor/gas"
#define TOPIC_SENSOR_FIRE     "home/" HOME_ID "/sensor/fire"
#define TOPIC_SENSOR_BIN      "home/" HOME_ID "/sensor/bin"
#define TOPIC_DEVICE_STATUS   "home/" HOME_ID "/device/" DEVICE_ID "/status"
#define TOPIC_COMMAND         "home/" HOME_ID "/device/" DEVICE_ID "/command"

// ── Relay Feature Flags ───────────────────────────────────────────────────────
// Comment relay yang tidak dipakai pada ESP ini

#define ENABLE_RELAY_1   // Pin 14
#define ENABLE_RELAY_2   // Pin 25
#define ENABLE_RELAY_3   // Pin 26
#define ENABLE_RELAY_4   // Pin 27

// ── Relay Pins (active LOW) ───────────────────────────────────────────────────
#define PIN_RELAY_1     14
#define PIN_RELAY_2     25
#define PIN_RELAY_3     26
#define PIN_RELAY_4     27

// ── PZEM-004T Serial ──────────────────────────────────────────────────────────
#define PZEM_RX_PIN     16   // ESP32 RX ← PZEM TX
#define PZEM_TX_PIN     17   // ESP32 TX → PZEM RX
#define PZEM_SERIAL     Serial2

// ── Sensor Feature Flags ──────────────────────────────────────────────────────
// Comment baris #define untuk menonaktifkan sensor tersebut.
// Jika di-comment, sensor tidak akan dibaca dan tidak akan dikirim ke MQTT.
//
// Contoh: jika ESP ini hanya pakai PZEM + MQ2, comment ENABLE_FLAME dan ENABLE_ULTRASONIC

#define ENABLE_PZEM          // PZEM-004T — pengukur daya listrik
// #define ENABLE_MQ2           // MQ-2 — sensor gas LPG/asap
// #define ENABLE_FLAME         // Flame sensor — deteksi api
// #define ENABLE_ULTRASONIC    // HC-SR04 — sensor jarak (level sampah)

// ── Sensor Pin Mapping ────────────────────────────────────────────────────────

#ifdef ENABLE_MQ2
  #define PIN_MQ2_ANALOG    34   // MQ-2 analog output (ADC1_CH6)
  #define PIN_MQ2_DIGITAL   35   // MQ-2 digital output (DO)
#endif

#ifdef ENABLE_FLAME
  #define PIN_FLAME_ANALOG  32   // Flame sensor analog
  #define PIN_FLAME_DIGITAL 33   // Flame sensor digital (DO)
#endif

#ifdef ENABLE_ULTRASONIC
  // Catatan: PIN_TRIG dan PIN_ECHO tidak boleh sama dengan relay
  // Jika relay 3 & 4 dipakai (pin 26 & 27), ganti pin ultrasonic
  #define PIN_TRIG          12   // HC-SR04 TRIG
  #define PIN_ECHO          13   // HC-SR04 ECHO
  #define BIN_HEIGHT_CM     30   // Tinggi tempat sampah dalam cm
#endif

// ── Buzzer ────────────────────────────────────────────────────────────────────
// #define ENABLE_BUZZER
#ifdef ENABLE_BUZZER
  #define PIN_BUZZER        25   // Buzzer aktif
#endif

// ── Mode Baca Sensor (Digital vs Analog) ─────────────────────────────────────
// Jika di-comment → sensor membaca pin DIGITAL (DO) dari modul (pakai potensiometer).
// Jika di-define  → sensor membaca pin ANALOG (AO) dan alert berdasarkan threshold software.
#define MQ2_USE_ANALOG_MODE    // MQ-2  : gunakan AO + threshold software
#define FLAME_USE_ANALOG_MODE  // Flame : gunakan AO + threshold software

// ── Threshold Alarm ───────────────────────────────────────────────────────────
#define GAS_THRESHOLD_PPM     50  // PPM gas di atas ini = alarm (mode analog)
#define FLAME_ANALOG_THRESHOLD 3000 // Nilai ADC di bawah ini = api terdeteksi (mode analog)
                                    // Sensor flame IR: makin dekat api → nilai makin rendah
#define BIN_FULL_PERCENT       80   // Level sampah di atas ini = penuh

// ── Nama Relay / Ruangan ──────────────────────────────────────────────────────
// Ubah di sini saja — berlaku untuk firmware log, Firestore, dan MQTT
#define RELAY_1_NAME  "Kamar Tidur"
#define RELAY_2_NAME  "Ruang Tamu"
#define RELAY_3_NAME  "Kamar Mandi"
#define RELAY_4_NAME  "Kipas"

// ── Nama Device ───────────────────────────────────────────────────────────────
// Nama yang tampil di aplikasi Flutter
#define DEVICE_DISPLAY_NAME  "Kontrol Lampu"

// ── Timing ────────────────────────────────────────────────────────────────────
#define SENSOR_INTERVAL_MS    5000    // Kirim data sensor setiap 5 detik
#define STATUS_INTERVAL_MS    30000   // Kirim status online setiap 30 detik
