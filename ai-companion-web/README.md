# 🤖 AI Companion Web UI

Web-based UI untuk AI Companion yang bisa jadi teman/pacar, melihat kamu via kamera, dan mengontrol smart home.

## ✨ Fitur

- 💬 **Chat UI** - Interface chat modern dengan real-time response
- 👁️ **Webcam** - AI bisa melihat kamu via browser webcam
- 🔊 **Voice** - Text-to-Speech via Web Speech API (no server dependency)
- 💡 **Smart Home Control** - Toggle lampu langsung dari UI
- 💕 **Personality** - Ganti mode teman/pacar dari sidebar
- 📊 **Mood Tracker** - Lihat affection & patience level real-time
- 😤 **Emotional Actions** - AI ngambek bisa matikan lampu!

## 🚀 Quick Start

```bash
cd ai-companion-web

# Install dependencies
pip install -r requirements.txt

# Setup environment
copy .env.example .env
# Edit .env → isi GEMINI_API_KEY

# Jalankan server
python app.py
```

Buka browser: **http://localhost:8000**

## 📁 Struktur

```
ai-companion-web/
├── app.py                   # FastAPI backend (REST + WebSocket)
├── ai_brain.py              # Core AI (OpenAI/Gemini)
├── personality.py           # Personality & mood system
├── smart_home_controller.py # Firebase command sender
├── config.py                # Configuration
├── requirements.txt         # Python dependencies
├── .env.example             # Template env
├── static/
│   ├── index.html           # Main UI page
│   ├── style.css            # Dark theme styling
│   └── app.js               # Frontend logic
└── README.md
```

## 🎮 Cara Pakai

1. **Chat** - Ketik pesan di input box, tekan Enter
2. **Kamera** - Klik toggle "📷" di sidebar, lalu klik 📸 untuk kirim foto bersama pesan
3. **Voice** - AI akan bicara otomatis (toggle di sidebar)
4. **Mode** - Pilih "Pacar" atau "Teman" di dropdown
5. **Lampu** - Klik icon lampu di sidebar untuk toggle manual
6. **Suruh AI** - Bilang "tolong matiin lampu kamar" dan AI akan eksekusi

## 🔧 API Endpoints

| Method | Endpoint                  | Deskripsi                |
| ------ | ------------------------- | ------------------------ |
| GET    | `/`                       | Halaman utama            |
| POST   | `/api/chat`               | Kirim pesan ke AI        |
| GET    | `/api/mood`               | Get mood saat ini        |
| POST   | `/api/settings`           | Update mode/nama         |
| GET    | `/api/smart-home/status`  | Status device            |
| GET    | `/api/smart-home/relays`  | Status relay             |
| POST   | `/api/smart-home/command` | Kirim command manual     |
| WS     | `/ws/chat`                | WebSocket real-time chat |

## 💡 Tips

- Bicara **manis** (sayang, cinta, cantik) → mood naik 😊
- Bicara **kasar** (bodoh, berisik) → patience turun, bisa ngambek 😤
- AI **ngambek** + patience < 25 → dia bisa matikan lampu! 💢
- **Minta maaf** → mood kembali normal 🥺
- Aktifkan **kamera** → AI bisa komentari penampilan/kondisi kamu
