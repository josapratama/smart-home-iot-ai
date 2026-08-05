#include <Arduino.h>
#include "config.h"
#include "wifi_manager.h"
#include "mqtt_client.h"
#include "sensors.h"
#include "actuators.h"
#include "firestore.h"
#include "soc/soc.h"           // untuk WRITE_PERI_REG
#include "soc/rtc_cntl_reg.h"  // untuk RTC_CNTL_BROWN_OUT_REG

unsigned long lastSensorTime = 0;
unsigned long lastStatusTime = 0;
bool deviceRegistered = false;

void setup() {
    Serial.begin(115200);
    delay(500);

    // Nonaktifkan brownout detector sementara saat startup
    // (MQ-2 heater menarik arus besar saat pertama nyala)
    WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);

    Serial.println("\n=============================");
    Serial.println("  Smart Home ESP32 Firmware  ");
    Serial.println("=============================");
    Serial.printf("Home ID  : %s\n", HOME_ID);
    Serial.printf("Device ID: %s\n", DEVICE_ID);
    Serial.println("-----------------------------");

    initActuators();
    initSensors();
    connectWifi();
    connectMqtt();

    // Daftarkan device + channel ke Firestore (sekali saat boot)
    if (isWifiConnected()) {
        deviceRegistered = firestoreRegisterDevice(HOME_ID, DEVICE_ID);
    }

    Serial.println("[Main] Setup complete.");

    // Aktifkan kembali brownout detector setelah startup stabil
    WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 1);
}

void loop() {
    if (!isWifiConnected()) connectWifi();
    if (!isMqttConnected()) connectMqtt();
    mqttLoop();

    // Coba register ulang jika belum berhasil
    if (!deviceRegistered && isWifiConnected()) {
        deviceRegistered = firestoreRegisterDevice(HOME_ID, DEVICE_ID);
    }

    unsigned long now = millis();

    if (now - lastSensorTime >= SENSOR_INTERVAL_MS) {
        lastSensorTime = now;
        publishSensorData();
    }

    if (now - lastStatusTime >= STATUS_INTERVAL_MS) {
        lastStatusTime = now;
        publishDeviceStatus(true);
        firestoreUpdateDeviceStatus(HOME_ID, DEVICE_ID, true);
    }
}
