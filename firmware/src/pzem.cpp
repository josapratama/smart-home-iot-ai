/**
 * PZEM-004T v3.0 — ModBus RTU implementation
 * Protocol: 9600 baud, 8N1
 *
 * Response registers (0x04, addr 0xF8, 10 registers):
 * Byte[3-4]   = Voltage    (x0.1 V)
 * Byte[5-6]   = Current L  (x0.001 A) — low word
 * Byte[7-8]   = Current H  (x0.001 A) — high word
 * Byte[9-10]  = Power L    (x0.1 W)
 * Byte[11-12] = Power H
 * Byte[13-14] = Energy L   (Wh)
 * Byte[15-16] = Energy H
 * Byte[17-18] = Frequency  (x0.1 Hz)
 * Byte[19-20] = PF         (x0.01)
 * Byte[21-22] = Alarm
 * Byte[23-24] = CRC
 */

#include "pzem.h"

static HardwareSerial* _serial = nullptr;

static uint16_t crc16(const uint8_t* data, uint16_t len) {
    uint16_t crc = 0xFFFF;
    for (uint16_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (uint8_t j = 0; j < 8; j++) {
            crc = (crc & 0x0001) ? ((crc >> 1) ^ 0xA001) : (crc >> 1);
        }
    }
    return crc;
}

void pzemInit(HardwareSerial& serial, int rxPin, int txPin) {
    _serial = &serial;
    _serial->begin(9600, SERIAL_8N1, rxPin, txPin);
    delay(200);
    Serial.println("[PZEM] ModBus RTU initialized");
}

PzemData pzemRead() {
    PzemData result = {0, 0, 0, 0, 0, 0, false};
    if (!_serial) return result;

    // Request frame: addr=0xF8, func=0x04, reg=0x0000, count=0x000A
    uint8_t req[8] = {0xF8, 0x04, 0x00, 0x00, 0x00, 0x0A, 0x00, 0x00};
    uint16_t crc = crc16(req, 6);
    req[6] = crc & 0xFF;
    req[7] = (crc >> 8) & 0xFF;

    // Flush
    while (_serial->available()) _serial->read();

    _serial->write(req, 8);
    _serial->flush();

    // Response: 1+1+1+20+2 = 25 bytes
    uint32_t t = millis();
    while (_serial->available() < 25 && millis() - t < 1000) delay(5);

    if (_serial->available() < 25) {
        Serial.println("[PZEM] Timeout");
        return result;
    }

    uint8_t res[25];
    _serial->readBytes(res, 25);

    // Validate CRC
    uint16_t rxCrc   = res[23] | ((uint16_t)res[24] << 8);
    uint16_t calcCrc = crc16(res, 23);
    if (rxCrc != calcCrc) {
        Serial.printf("[PZEM] CRC error: got 0x%04X, expected 0x%04X\n", rxCrc, calcCrc);
        return result;
    }

    // Parse — data starts at byte 3
    // Voltage: reg[0] = bytes 3-4
    uint16_t voltRaw  = ((uint16_t)res[3] << 8) | res[4];

    // Current: reg[1]=low bytes 5-6, reg[2]=high bytes 7-8
    // Combined: high_word << 16 | low_word
    uint32_t currRaw  = ((uint32_t)res[5] << 8 | res[6])           // low word
                      | ((uint32_t)((uint16_t)res[7] << 8 | res[8]) << 16); // high word

    // Power: reg[3]=low bytes 9-10, reg[4]=high bytes 11-12
    uint32_t powRaw   = ((uint32_t)res[9]  << 8 | res[10])
                      | ((uint32_t)((uint16_t)res[11] << 8 | res[12]) << 16);

    // Energy: reg[5]=low bytes 13-14, reg[6]=high bytes 15-16
    uint32_t engRaw   = ((uint32_t)res[13] << 8 | res[14])
                      | ((uint32_t)((uint16_t)res[15] << 8 | res[16]) << 16);

    // Frequency: reg[7] = bytes 17-18
    uint16_t freqRaw  = ((uint16_t)res[17] << 8) | res[18];

    // PF: reg[8] = bytes 19-20
    uint16_t pfRaw    = ((uint16_t)res[19] << 8) | res[20];

    result.voltage   = voltRaw  * 0.1f;
    result.current   = currRaw  * 0.001f;
    result.power     = powRaw   * 0.1f;
    result.energy    = engRaw   * 1.0f;    // Wh (bukan kWh langsung)
    result.frequency = freqRaw  * 0.1f;
    result.pf        = pfRaw    * 0.01f;
    result.valid     = (result.voltage > 10.0f && result.voltage < 300.0f
                     && result.current < 100.0f);  // sanity check

    if (!result.valid) {
        Serial.printf("[PZEM] Sanity check failed: V=%.1f I=%.3f\n",
            result.voltage, result.current);
        result.valid = false;
    }

    return result;
}
