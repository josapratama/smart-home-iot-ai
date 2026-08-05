"""Konfigurasi AI Companion Web - Multi Provider."""

import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")


class Config:
    # AI Provider: "openai", "claude", "groq", "gemini", "ollama"
    AI_PROVIDER: str = os.getenv("AI_PROVIDER", "gemini")

    # OpenAI
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-4o")

    # Claude (Anthropic)
    CLAUDE_API_KEY: str = os.getenv("CLAUDE_API_KEY", "")
    CLAUDE_MODEL: str = os.getenv("CLAUDE_MODEL", "claude-sonnet-4-20250514")

    # Groq
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
    GROQ_MODEL: str = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")

    # Gemini
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")

    # Ollama (local)
    OLLAMA_HOST: str = os.getenv("OLLAMA_HOST", "http://localhost:11434")
    OLLAMA_MODEL: str = os.getenv("OLLAMA_MODEL", "llava")

    # Firebase
    FIREBASE_CREDENTIALS: str = os.getenv(
        "FIREBASE_CREDENTIALS",
        "../ai/smarthome-cfd3f-firebase-adminsdk-fbsvc-61519df010.json"
    )

    # Smart Home
    HOME_ID: str = os.getenv("HOME_ID", "j2QdNiBNAKrbgYayYMia")
    DEVICE_ID: str = os.getenv("DEVICE_ID", "device_esp32_01")

    # Companion
    COMPANION_MODE: str = os.getenv("COMPANION_MODE", "pacar")
    COMPANION_NAME: str = os.getenv("COMPANION_NAME", "Aria")
    USER_NAME: str = os.getenv("USER_NAME", "Sayang")

    # Relay mapping (sesuai config.h firmware)
    RELAY_MAP: dict = {
        "kamar tidur": {"pin": 14, "channel": 1},
        "ruang tamu": {"pin": 25, "channel": 2},
        "kamar mandi": {"pin": 26, "channel": 3},
        "dapur": {"pin": 27, "channel": 4},
        "lampu kamar": {"pin": 14, "channel": 1},
        "lampu tamu": {"pin": 25, "channel": 2},
        "lampu kamar mandi": {"pin": 26, "channel": 3},
        "lampu dapur": {"pin": 27, "channel": 4},
    }

    # Scenes
    SCENES: dict = {
        "sleep": {"name": "Sleep Mode", "icon": "🌙", "actions": [
            {"target": "kamar tidur", "state": "off"},
            {"target": "ruang tamu", "state": "off"},
            {"target": "kamar mandi", "state": "off"},
            {"target": "dapur", "state": "off"},
        ]},
        "welcome": {"name": "Welcome Home", "icon": "🏠", "actions": [
            {"target": "kamar tidur", "state": "on"},
            {"target": "ruang tamu", "state": "on"},
        ]},
        "movie": {"name": "Movie Mode", "icon": "🎬", "actions": [
            {"target": "ruang tamu", "state": "off"},
            {"target": "kamar tidur", "state": "off"},
            {"target": "dapur", "state": "on"},
        ]},
        "cooking": {"name": "Cooking Mode", "icon": "🍳", "actions": [
            {"target": "dapur", "state": "on"},
            {"target": "ruang tamu", "state": "on"},
        ]},
    }

    AVAILABLE_PROVIDERS: list = [
        {"id": "openai", "name": "OpenAI GPT-4o", "icon": "🟢", "vision": True},
        {"id": "claude", "name": "Claude (Anthropic)", "icon": "🟠", "vision": True},
        {"id": "groq", "name": "Groq (Llama/Mixtral)", "icon": "⚡", "vision": False},
        {"id": "gemini", "name": "Google Gemini", "icon": "🔵", "vision": True},
        {"id": "ollama", "name": "Ollama (Local)", "icon": "🏠", "vision": True},
    ]


config = Config()
