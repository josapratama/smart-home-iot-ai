#pragma once

void connectMqtt();
bool isMqttConnected();
void mqttLoop();
void mqttPublish(const char* topic, const char* payload, bool retain = false);
