#include <Arduino.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "config.h"
#include "mqtt_client.h"
#include "actuators.h"
#include "firestore.h"

WiFiClientSecure wifiClient;
PubSubClient     mqttClient(wifiClient);

// Callback: dipanggil saat ada pesan masuk dari broker
void onMessageReceived(char* topic, byte* payload, unsigned int length) {
    String topicStr(topic);
    String payloadStr;
    for (unsigned int i = 0; i < length; i++) {
        payloadStr += (char)payload[i];
    }

    Serial.printf("[MQTT] Received [%s]: %s\n", topic, payloadStr.c_str());

    // Handle perintah kontrol relay
    if (topicStr == TOPIC_COMMAND) {
        StaticJsonDocument<128> doc;
        DeserializationError err = deserializeJson(doc, payloadStr);
        if (err) return;

        int   pin   = doc["pin"]   | -1;
        bool  state = doc["state"] | false;

        if (pin > 0) {
            setRelay(pin, state);
            Serial.printf("[Relay] Pin %d -> %s\n", pin, state ? "ON" : "OFF");
            // Sinkronkan state ke Firestore agar UI Flutter update
            firestoreUpdateChannelState(HOME_ID, DEVICE_ID, pin, state);
        }
    }
}

void connectMqtt() {
    wifiClient.setInsecure(); // Untuk dev — ganti dengan CA cert di production

    mqttClient.setServer(MQTT_HOST, MQTT_PORT);
    mqttClient.setCallback(onMessageReceived);
    mqttClient.setKeepAlive(60);
    mqttClient.setBufferSize(512);

    Serial.print("[MQTT] Connecting...");
    int retries = 0;
    while (!mqttClient.connected() && retries < 5) {
        if (mqttClient.connect(MQTT_CLIENT_ID, MQTT_USER, MQTT_PASSWORD)) {
            Serial.println(" Connected!");
            mqttClient.subscribe(TOPIC_COMMAND);
            Serial.printf("[MQTT] Subscribed to: %s\n", TOPIC_COMMAND);
        } else {
            Serial.printf(" Failed (rc=%d). Retry %d/5\n", mqttClient.state(), ++retries);
            delay(2000);
        }
    }
}

bool isMqttConnected() {
    return mqttClient.connected();
}

void mqttLoop() {
    mqttClient.loop();
}

void mqttPublish(const char* topic, const char* payload, bool retain) {
    if (!mqttClient.connected()) return;
    mqttClient.publish(topic, payload, retain);
    Serial.printf("[MQTT] Published [%s]: %s\n", topic, payload);
}
