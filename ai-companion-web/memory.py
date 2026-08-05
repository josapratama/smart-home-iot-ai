"""
Memory Module - Persistent conversation & user preferences.
Stores conversations and learned facts to Firestore.
Handles missing indexes gracefully.
"""

from firebase_admin import firestore
from typing import Optional


class Memory:
    """Persistent memory for AI Companion."""

    def __init__(self, db, user_id: str = "default"):
        self.db = db
        self.user_id = user_id
        self.collection = "ai_companion_memory"

    def save_message(self, role: str, content: str, mood: str = "neutral"):
        """Save a chat message to Firestore."""
        try:
            self.db.collection(self.collection).document(self.user_id) \
                .collection("messages").add({
                    "role": role,
                    "content": content,
                    "mood": mood,
                    "timestamp": firestore.SERVER_TIMESTAMP,
                })
        except Exception:
            pass

    def get_recent_messages(self, limit: int = 20) -> list[dict]:
        """Get recent messages from memory."""
        try:
            docs = (
                self.db.collection(self.collection).document(self.user_id)
                .collection("messages")
                .order_by("timestamp", direction=firestore.Query.DESCENDING)
                .limit(limit)
                .stream()
            )
            messages = []
            for doc in docs:
                d = doc.to_dict()
                messages.append({
                    "role": d.get("role", "user"),
                    "content": d.get("content", ""),
                    "mood": d.get("mood", "neutral"),
                })
            messages.reverse()
            return messages
        except Exception:
            return []

    def save_fact(self, fact: str, category: str = "general"):
        """Save a learned fact about the user."""
        try:
            self.db.collection(self.collection).document(self.user_id) \
                .collection("facts").add({
                    "fact": fact,
                    "category": category,
                    "timestamp": firestore.SERVER_TIMESTAMP,
                })
        except Exception:
            pass

    def get_facts(self, limit: int = 20) -> list[str]:
        """Get learned facts about the user."""
        try:
            docs = (
                self.db.collection(self.collection).document(self.user_id)
                .collection("facts")
                .order_by("timestamp", direction=firestore.Query.DESCENDING)
                .limit(limit)
                .stream()
            )
            return [doc.to_dict().get("fact", "") for doc in docs]
        except Exception:
            return []

    def save_personality_state(self, state: dict):
        """Save personality state (mood, affection, etc)."""
        try:
            self.db.collection(self.collection).document(self.user_id).set(
                {"personality": state, "updated_at": firestore.SERVER_TIMESTAMP},
                merge=True
            )
        except Exception:
            pass

    def load_personality_state(self) -> Optional[dict]:
        """Load saved personality state."""
        try:
            doc = self.db.collection(self.collection).document(self.user_id).get()
            if doc.exists:
                return doc.to_dict().get("personality")
        except Exception:
            pass
        return None

    def save_mood_history(self, mood: str, trigger: str):
        """Save mood change for visualization."""
        try:
            self.db.collection(self.collection).document(self.user_id) \
                .collection("mood_history").add({
                    "mood": mood,
                    "trigger": trigger,
                    "timestamp": firestore.SERVER_TIMESTAMP,
                })
        except Exception:
            pass

    def get_mood_history(self, limit: int = 50) -> list[dict]:
        """Get mood history for chart."""
        try:
            docs = (
                self.db.collection(self.collection).document(self.user_id)
                .collection("mood_history")
                .order_by("timestamp", direction=firestore.Query.DESCENDING)
                .limit(limit)
                .stream()
            )
            history = []
            for doc in docs:
                d = doc.to_dict()
                ts = d.get("timestamp")
                history.append({
                    "mood": d.get("mood", "neutral"),
                    "trigger": d.get("trigger", ""),
                    "timestamp": ts.isoformat() if ts else "",
                })
            history.reverse()
            return history
        except Exception:
            return []
