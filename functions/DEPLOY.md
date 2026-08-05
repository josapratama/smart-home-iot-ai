# Cara Deploy Cloud Functions

## Prasyarat

- Firebase CLI sudah terinstall (`npm install -g firebase-tools`)
- Sudah login Firebase (`firebase login`)
- HiveMQ Cloud account sudah dibuat di https://www.hivemq.com/mqtt-cloud-broker/

## Langkah Deploy

### 1. Login Firebase

```bash
firebase login
```

### 2. Set konfigurasi HiveMQ

Ganti nilai di bawah dengan kredensial HiveMQ kamu:

```bash
firebase functions:config:set \
  hivemq.host="YOUR_HOST.s2.eu.hivemq.cloud" \
  hivemq.user="YOUR_USERNAME" \
  hivemq.password="YOUR_PASSWORD"
```

### 3. Deploy semua functions

```bash
cd functions
npm run deploy
```

### 4. Verifikasi

Buka Firebase Console → Functions → lihat 3 function:

- `mqttBridge` (HTTP trigger)
- `onAlarmCreate` (Firestore trigger)
- `onCommandCreate` (Firestore trigger)

### 5. Aktifkan MQTT Bridge

Setelah deploy, panggil endpoint `mqttBridge` sekali via browser atau curl:

```
https://us-central1-smarthome-cfd3f.cloudfunctions.net/mqttBridge
```

## Catatan

- `mqttBridge`: Menerima data sensor dari ESP32 via MQTT → tulis ke Firestore
- `onAlarmCreate`: Kirim push notification FCM saat ada alarm baru
- `onCommandCreate`: Forward perintah on/off dari Firestore ke ESP32 via MQTT
