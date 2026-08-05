#include <Arduino.h>
#include <WiFi.h>
#include <time.h>
#include "config.h"
#include "wifi_manager.h"

void connectWifi() {
    if (WiFi.status() == WL_CONNECTED) return;

    Serial.printf("[WiFi] Connecting to %s", WIFI_SSID);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    int retries = 0;
    while (WiFi.status() != WL_CONNECTED && retries < 20) {
        delay(500);
        Serial.print(".");
        retries++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.printf("\n[WiFi] Connected. IP: %s\n", WiFi.localIP().toString().c_str());

        // Sync waktu via NTP agar timestamp Firestore akurat
        configTime(0, 0, "pool.ntp.org", "time.nist.gov");
        Serial.print("[WiFi] Syncing NTP time");
        struct tm timeinfo;
        int ntpRetry = 0;
        while (!getLocalTime(&timeinfo) && ntpRetry < 10) {
            delay(500);
            Serial.print(".");
            ntpRetry++;
        }
        if (getLocalTime(&timeinfo)) {
            char buf[32];
            strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);
            Serial.printf("\n[WiFi] NTP synced: %s\n", buf);
        } else {
            Serial.println("\n[WiFi] NTP sync failed, using fallback timestamp");
        }
    } else {
        Serial.println("\n[WiFi] Failed. Retrying on next loop.");
    }
}

bool isWifiConnected() {
    return WiFi.status() == WL_CONNECTED;
}
