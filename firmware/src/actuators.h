#pragma once

void initActuators();
void setRelay(int pin, bool state);
bool getRelayState(int pin);
void publishDeviceStatus(bool isOnline);
