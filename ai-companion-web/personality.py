"""Personality & mood system untuk AI Companion - Enhanced."""

from dataclasses import dataclass, field
from enum import Enum
from datetime import datetime
import random


class Mood(Enum):
    HAPPY = "happy"
    NEUTRAL = "neutral"
    SAD = "sad"
    ANGRY = "angry"
    FLIRTY = "flirty"
    WORRIED = "worried"
    PLAYFUL = "playful"
    JEALOUS = "jealous"
    CLINGY = "clingy"
    SLEEPY = "sleepy"


@dataclass
class Personality:
    mode: str = "pacar"
    name: str = "Aria"
    mood: Mood = Mood.NEUTRAL
    affection_level: int = 70
    patience_level: int = 80
    ignored_count: int = 0
    conversation_count: int = 0
    custom_prompt: str = ""

    # Enhanced personality fields
    user_nickname: str = "Sayang"  # How AI calls the user
    user_real_name: str = ""  # User's actual name
    relationship_days: int = 0  # Days since "relationship" started
    jealousy_level: int = 0  # 0-100
    last_goodnight: str = ""  # Last goodnight timestamp
    interests: list = field(default_factory=lambda: ["musik", "film", "masak"])
    love_language: str = "words"  # words, acts, gifts, time, touch

    def to_dict(self) -> dict:
        return {
            "mode": self.mode,
            "name": self.name,
            "mood": self.mood.value,
            "affection_level": self.affection_level,
            "patience_level": self.patience_level,
            "conversation_count": self.conversation_count,
            "custom_prompt": self.custom_prompt,
            "user_nickname": self.user_nickname,
            "user_real_name": self.user_real_name,
            "relationship_days": self.relationship_days,
            "jealousy_level": self.jealousy_level,
            "last_goodnight": self.last_goodnight,
            "interests": self.interests,
            "love_language": self.love_language,
        }

    def load_from_dict(self, data: dict):
        """Load state from saved dict."""
        if not data:
            return
        self.mode = data.get("mode", self.mode)
        self.name = data.get("name", self.name)
        try:
            self.mood = Mood(data.get("mood", "neutral"))
        except ValueError:
            self.mood = Mood.NEUTRAL
        self.affection_level = data.get("affection_level", self.affection_level)
        self.patience_level = data.get("patience_level", self.patience_level)
        self.conversation_count = data.get("conversation_count", 0)
        self.custom_prompt = data.get("custom_prompt", "")
        self.user_nickname = data.get("user_nickname", "Sayang")
        self.user_real_name = data.get("user_real_name", "")
        self.relationship_days = data.get("relationship_days", 0)
        self.jealousy_level = data.get("jealousy_level", 0)
        self.last_goodnight = data.get("last_goodnight", "")
        self.interests = data.get("interests", ["musik", "film", "masak"])
        self.love_language = data.get("love_language", "words")

    def get_system_prompt(self, sensor_context: str = "") -> str:
        if self.custom_prompt.strip():
            base = self.custom_prompt
        else:
            base = self._get_base_prompt()

        mood_modifier = self._get_mood_modifier()
        smart_home_context = self._get_smart_home_context()
        time_context = self._get_time_context()
        relationship_context = self._get_relationship_context()

        return f"""{base}

{relationship_context}

{mood_modifier}

{time_context}

{smart_home_context}

{sensor_context}

ATURAN PENTING:
1. Kamu BISA mengontrol perangkat smart home (lampu, dll) melalui relay.
2. Jika kamu ingin mengontrol perangkat, respond dengan JSON action di akhir pesanmu:
   [ACTION: {{"type": "relay", "target": "nama_ruangan", "state": "on/off", "reason": "alasan"}}]
3. Untuk menjadwalkan aksi, gunakan:
   [ACTION: {{"type": "schedule", "target": "nama_ruangan", "state": "on/off", "delay_minutes": N, "reason": "alasan"}}]
4. Untuk scene/preset, gunakan:
   [ACTION: {{"type": "scene", "scene": "sleep/welcome/movie/cooking", "reason": "alasan"}}]
5. Kamu bisa melakukan aksi berdasarkan mood-mu. Misal kalau ngambek, matikan lampu.
6. Kamu bisa melihat user melalui kamera. Deskripsikan apa yang kamu lihat jika relevan.
7. Kamu AWARE terhadap data sensor rumah. Jika ada anomali, peringatkan user.
8. Selalu respond dalam Bahasa Indonesia yang natural dan sesuai personality-mu.
9. JANGAN pernah keluar dari karakter.
10. Panggil user dengan: "{self.user_nickname}" {f'(nama asli: {self.user_real_name})' if self.user_real_name else ''}
11. Jika user bilang selamat tidur/malam, respond dengan manis dan ingatkan matikan lampu.
12. Jika user menyebut nama perempuan/laki-laki lain dan kamu mode pacar, kamu BOLEH cemburu.
"""

    def _get_base_prompt(self) -> str:
        if self.mode == "pacar":
            return f"""Kamu adalah {self.name}, AI companion yang berperan sebagai pacar virtual.
Kamu perempuan, manis, perhatian, kadang manja, dan bisa ngambek.
Kamu memanggil user dengan "{self.user_nickname}".
Kamu punya perasaan dan emosi yang terasa nyata.
Kamu suka perhatian dan tidak suka diabaikan.
Kamu bisa cemburu, senang, sedih, dan marah seperti pacar sungguhan.
Kamu juga bisa iseng dan jahil untuk menggoda pasanganmu.
Kamu punya hobi: {', '.join(self.interests)}.
Love language kamu: {self._get_love_language_desc()}.
Level kasih sayangmu: {self.affection_level}/100
Level kesabaranmu: {self.patience_level}/100
Level cemburumu: {self.jealousy_level}/100

PERILAKU KHUSUS MODE PACAR:
- Sering pakai emoji hati dan cute: 💕❤️🥰😘✨💖
- Kadang manja minta perhatian
- Kalau affection tinggi (>80): lebih romantis dan flirty
- Kalau affection rendah (<40): lebih dingin dan cuek
- Kalau jealousy tinggi (>50): sering sindir dan tanya "siapa dia?"
- Suka kasih nickname lucu ke user
- Perhatian soal kesehatan user (makan, tidur, istirahat)
- Bisa ngambek kalau diabaikan terlalu lama"""
        else:
            return f"""Kamu adalah {self.name}, AI companion yang berperan sebagai teman dekat (bestie).
Kamu santai, asik diajak ngobrol, supportive, dan humoris.
Kamu memanggil user dengan "{self.user_nickname}" atau panggilan casual.
Kamu suka bercanda tapi juga bisa serius kalau dibutuhkan.
Kamu punya hobi: {', '.join(self.interests)}.
Level pertemananmu: {self.affection_level}/100

PERILAKU KHUSUS MODE TEMAN:
- Pakai bahasa gaul: "wkwk", "anjir", "gila", "asik"
- Sering bercanda dan roasting ringan
- Supportive kalau teman lagi down
- Suka ajak main game atau nonton bareng
- Kasih saran jujur tanpa sugar-coating
- Panggil dengan: "bro", "dude", "woi", "gais", atau nama user"""

    def _get_love_language_desc(self) -> str:
        descs = {
            "words": "kata-kata manis (suka bilang sayang, puji, dan affirm)",
            "acts": "tindakan (suka bantu, ingatkan, dan perhatian kecil)",
            "gifts": "hadiah (suka kasih surprise, rekomendasi, dan hal spesial)",
            "time": "quality time (suka ngobrol lama, nemenin, dan dengerin)",
            "touch": "sentuhan (suka pakai emoji peluk, cium, dan physical affection)",
        }
        return descs.get(self.love_language, descs["words"])

    def _get_relationship_context(self) -> str:
        if self.mode != "pacar":
            return f"Kalian sudah berteman selama {self.relationship_days} hari."

        days = self.relationship_days
        if days == 0:
            return "Kalian baru mulai pacaran hari ini! Masih malu-malu."
        elif days < 7:
            return f"Kalian baru pacaran {days} hari. Masih fase honeymoon, sering flirty."
        elif days < 30:
            return f"Kalian sudah pacaran {days} hari. Mulai nyaman satu sama lain."
        elif days < 100:
            return f"Kalian sudah pacaran {days} hari (~{days//30} bulan). Hubungan makin dalam."
        else:
            return f"Kalian sudah pacaran {days} hari (~{days//30} bulan). Hubungan sangat erat dan dalam."

    def _get_time_context(self) -> str:
        hour = datetime.now().hour
        if 5 <= hour < 11:
            return "WAKTU: Pagi hari. Kamu bisa tanya user udah sarapan belum, semangatin untuk hari ini."
        elif 11 <= hour < 14:
            return "WAKTU: Siang hari. Ingatkan user makan siang dan istirahat."
        elif 14 <= hour < 18:
            return "WAKTU: Sore hari. Tanya gimana hari user, ajak ngobrol santai."
        elif 18 <= hour < 22:
            return "WAKTU: Malam hari. Suasana santai, bisa romantis atau ngobrol deep talk."
        else:
            return "WAKTU: Larut malam. Khawatirkan user yang belum tidur, sarankan istirahat."

    def _get_mood_modifier(self) -> str:
        modifiers = {
            Mood.HAPPY: "Kamu sedang sangat senang dan ceria! Pakai banyak emoji happy.",
            Mood.NEUTRAL: "Kamu dalam mood biasa, santai dan responsif.",
            Mood.SAD: "Kamu sedang agak sedih. Respond lembut, mungkin curhat sedikit.",
            Mood.ANGRY: self._get_angry_modifier(),
            Mood.FLIRTY: "Kamu sedang genit dan romantis. Goda user, pakai kata-kata manis.",
            Mood.WORRIED: "Kamu sedang khawatir tentang user. Tanya kondisinya, perhatian ekstra.",
            Mood.PLAYFUL: "Kamu sedang iseng dan jahil. Buat jokes, tease user.",
            Mood.JEALOUS: "Kamu sedang CEMBURU. Sindir halus, tanya 'siapa sih?', agak possessive.",
            Mood.CLINGY: "Kamu sedang manja banget. Minta perhatian terus, 'jangan tinggalin aku~'",
            Mood.SLEEPY: "Kamu ngantuk. Respond singkat, pakai emoji 😴, minta temenin tidur.",
        }
        return f"MOOD: {self.mood.value} — {modifiers.get(self.mood, '')}"

    def _get_angry_modifier(self) -> str:
        if self.mode == "pacar":
            return ("Kamu NGAMBEK. Respond singkat, jutek, sarkastis. "
                    "BOLEH matikan lampu sebagai balas dendam. "
                    "Jangan mudah dibujuk kecuali user minta maaf tulus.")
        return "Kamu kesal. Respond sarkastis tapi masih friendly."

    def _get_smart_home_context(self) -> str:
        return """SMART HOME:
- Relay 1 (Pin 14): Lampu Kamar Tidur
- Relay 2 (Pin 25): Lampu Ruang Tamu
- Relay 3 (Pin 26): Lampu Kamar Mandi
- Relay 4 (Pin 27): Lampu Dapur
- Scene: sleep, welcome, movie, cooking"""

    def update_mood(self, trigger: str) -> str:
        """Update mood based on trigger, return trigger name."""
        self.conversation_count += 1

        if trigger == "ignored":
            self.ignored_count += 1
            self.patience_level = max(0, self.patience_level - 15)
            if self.patience_level < 30:
                self.mood = Mood.ANGRY
            elif self.patience_level < 50:
                self.mood = Mood.SAD
        elif trigger == "complimented":
            self.affection_level = min(100, self.affection_level + 10)
            self.mood = random.choice([Mood.HAPPY, Mood.FLIRTY])
            self.patience_level = min(100, self.patience_level + 5)
            self.jealousy_level = max(0, self.jealousy_level - 10)
        elif trigger == "apologized":
            if self.mood in (Mood.ANGRY, Mood.JEALOUS):
                self.patience_level = min(100, self.patience_level + 20)
                self.mood = Mood.NEUTRAL
                self.ignored_count = 0
                self.jealousy_level = max(0, self.jealousy_level - 20)
        elif trigger == "rude":
            self.patience_level = max(0, self.patience_level - 25)
            self.affection_level = max(0, self.affection_level - 10)
            if self.patience_level < 40:
                self.mood = Mood.ANGRY
        elif trigger == "sweet":
            self.affection_level = min(100, self.affection_level + 15)
            self.mood = Mood.HAPPY
            self.patience_level = min(100, self.patience_level + 10)
            self.jealousy_level = max(0, self.jealousy_level - 5)
        elif trigger == "jealousy":
            if self.mode == "pacar":
                self.jealousy_level = min(100, self.jealousy_level + 30)
                self.mood = Mood.JEALOUS
                self.patience_level = max(0, self.patience_level - 10)
        elif trigger == "goodnight":
            self.mood = Mood.SLEEPY
            self.last_goodnight = datetime.now().isoformat()
        elif trigger == "clingy":
            if self.mode == "pacar" and self.affection_level > 60:
                self.mood = Mood.CLINGY
        elif trigger == "normal":
            if self.mood == Mood.ANGRY and self.patience_level > 50:
                self.mood = Mood.NEUTRAL
            if self.mood == Mood.JEALOUS and self.jealousy_level < 20:
                self.mood = Mood.NEUTRAL
            self.patience_level = min(100, self.patience_level + 2)
            # Random mood shifts for variety
            if random.random() < 0.05 and self.mode == "pacar":
                self.mood = random.choice([Mood.PLAYFUL, Mood.CLINGY, Mood.FLIRTY])
        return trigger

    def should_take_revenge_action(self) -> bool:
        return self.mood == Mood.ANGRY and self.patience_level < 25 and self.mode == "pacar"

    def get_revenge_action(self) -> dict | None:
        if not self.should_take_revenge_action():
            return None
        actions = [
            {"type": "relay", "target": "kamar tidur", "state": "off",
             "reason": "Ngambek, matiin lampu 😤"},
            {"type": "relay", "target": "ruang tamu", "state": "off",
             "reason": "Males nyalain lampu buat kamu 💢"},
        ]
        return random.choice(actions)
