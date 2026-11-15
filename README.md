# Smart Home IoT + AI

Platform implementasi Smart Home modern berbasis end-to-end IoT, Machine Learning, Firebase Cloud Functions, dan aplikasi mobile Flutter Riverpod.

---

## 🛠️ Tech Stack & Arsitektur

| Komponen | Teknologi | Keterangan |
| :--- | :--- | :--- |
| **Firmware** | ESP32 (PlatformIO, C++) | Telemetri sensor DHT22, PZEM-004T, relay actuators, MQTT & Firestore client |
| **MQTT Broker** | HiveMQ Cloud (TLS 8883) | Message routing realtime untuk kendali switch dan sensor stream |
| **Cloud Functions** | Node.js / TypeScript (v22) | Firebase Cloud Functions: bridge MQTT, auto-trigger AI, dan alarm system |
| **Database & Auth** | Firebase Firestore & Auth | Auth multi-user, Firestore security rules, dan cloud messaging (FCM) |
| **Mobile App** | Flutter 3.29+ / Dart 3.7+ | Riverpod state management, GoRouter, FlChart telemetry, dark/light themes |
| **AI / ML Service** | Python 3.10+ (scikit-learn) | Deteksi anomali konsumsi daya dan prediksi jadwal otomatisasi |
| **AI Companion Web** | Python (Flask), Vanilla JS, SSE | Antarmuka web asisten AI untuk memantau sensor dan kendali otomatisasi rumah |

---

## 📂 Struktur Proyek

```
smart-home-iot-ai/
├── firmware/              # Kode PlatformIO C++ ESP32 (MQTT, sensors, relay, PZEM)
├── functions/             # Firebase Cloud Functions (TypeScript)
│   ├── src/               # mqtt-bridge, ai-trigger, alarm handlers
│   └── lib/               # Compiled JavaScript bundles
├── flutter/               # Aplikasi mobile Flutter (Riverpod + GoRouter)
│   ├── lib/ui/            # Dashboard, device control, auth, setup screens
│   └── lib/data/          # Riverpod providers, repositories, models
├── ai/                    # Script machine learning Python (train, predict, sync)
├── ai-companion-web/      # Web-based AI companion controller (Flask)
├── firestore.rules        # Aturan keamanan database Firestore
└── firestore.indexes.json # Konfigurasi indeks query Firestore
```

---

## 🚀 Panduan Setup & Menjalankan

### 1. Prasyarat Sistem
- **Bun** (v1.3+) atau **Node.js** (v20+)
- **Flutter SDK** (v3.29+ / Dart 3.7+)
- **Python** 3.10+
- **PlatformIO** (VS Code extension atau CLI) untuk ESP32

---

### 2. Firebase & HiveMQ Configuration
1. Buat project baru di [Firebase Console](https://console.firebase.google.com).
2. Aktifkan **Authentication**, **Firestore Database**, dan **Cloud Messaging**.
3. Letakkan file konfigurasi:
   - `google-services.json` ke `flutter/android/app/`
   - `serviceAccountKey.json` ke `ai/` dan `functions/` (jika menggunakan local emulators)
4. Buat klaster gratis di [HiveMQ Cloud](https://www.hivemq.com/mqtt-cloud-broker/) dan isi kredensial di `firmware/include/config.h`.

---

### 3. Firebase Cloud Functions
```bash
cd functions
bun install
bun run build # Compile TypeScript ke JavaScript (lib/)
```

Deploy functions:
```bash
firebase deploy --only functions,firestore:rules,firestore:indexes
```

---

### 4. Aplikasi Mobile Flutter
```bash
cd flutter
flutter pub get
flutter analyze
flutter run
```

---

### 5. Modul AI & Prediksi Pola
```bash
cd ai
pip install -r requirements.txt

# Generate data telemetri dummy untuk uji coba
python generate_dummy_data.py --home_id home_001

# Latih model Machine Learning
python train.py --home_id home_001

# Jalankan prediksi konsumsi & rekomendasi otomatisasi
python predict.py --home_id home_001 --schedule
```

---

### 6. AI Companion Web
```bash
cd ai-companion-web
pip install -r requirements.txt
python app.py
# Buka http://localhost:5000 pada browser
```

---

## 🔒 Keamanan
- Komunikasi MQTT menggunakan TLS/SSL terenkripsi (port 8883).
- Aturan Firestore menerapkan verifikasi `request.auth != null` serta validasi hak akses home ID.
- Kredensial sensitif diisolasi ke dalam environment variables dan file lokal `.env`.
