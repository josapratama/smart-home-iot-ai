#pragma once
#include <Arduino.h>

struct PzemData {
    float voltage;    // Volt
    float current;    // Ampere
    float power;      // Watt
    float energy;     // kWh
    float frequency;  // Hz
    float pf;         // Power Factor
    bool  valid;
};

void   pzemInit(HardwareSerial& serial, int rxPin, int txPin);
PzemData pzemRead();
