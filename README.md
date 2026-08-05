# Smart Home IoT + AI

Implementasi Smart Home Berbasis IoT dan AI dengan Kendali Flutter

## Stack

| Komponen       | Teknologi                             |
| -------------- | ------------------------------------- |
| Mikrokontroler | ESP32 (PlatformIO)                    |
| MQTT Broker    | HiveMQ Cloud                          |
| Database       | Firebase Firestore                    |
| Auth           | Firebase Authentication               |
| Notifikasi     | Firebase Cloud Messaging              |
| Backend Logic  | Firebase Cloud Functions (TypeScript) |
| Mobile App     | Flutter (Dart)                        |
| AI/ML          | Python (scikit-learn)                 |

## Struktur Folder

```
smart-home/
├── firmware/     # Kode ESP32
├── functions/    # Firebase Cloud Functions
├── flutter/      # Aplikasi Flutter
├── ai/           # Modul AI Python
└── docs/         # Dokumentasi
```

## Quick Start

### 1. Firebase Setup

1. Buat project di [Firebase Console](https://console.firebase.google.com)
2. Aktifkan: Authentication, Firestore, Realtime Database, Cloud Messaging, Functions
3. Download `google-services.json` → letakkan di `flutter/android/app/`
4. Download `serviceAccountKey.json` → letakkan di `ai/`

### 2. HiveMQ Cloud

1. Daftar di [HiveMQ Cloud](https://www.hivemq.com/mqtt-cloud-broker/)
2. Catat: host, username, password
3. Isi di `firmware/include/config.h`
4. Set Firebase Functions config:
   ```bash
   firebase functions:config:set hivemq.host="..." hivemq.user="..." hivemq.password="..."
   ```

### 3. Firmware ESP32

```bash
cd firmware
# Install PlatformIO extension di VS Code
# Buka folder firmware, klik Upload
```

### 4. Cloud Functions

```bash
cd functions
npm install
npm run deploy
```

### 5. Flutter

```bash
cd flutter
flutter pub get
flutter run
```

### 6. AI Module

```bash
cd ai
pip install -r requirements.txt
# Letakkan serviceAccountKey.json di folder ini
python train.py --home_id home_001
python predict.py --home_id home_001 --schedule
```
