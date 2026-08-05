"""
AI Brain - Multi-provider AI engine.
Supports: OpenAI, Claude, Groq, Gemini, Ollama.
"""

import json
import re
import base64
import asyncio
from config import config
from personality import Personality


class AIBrain:
    """Multi-provider AI brain."""

    def __init__(self, personality: Personality):
        self.personality = personality
        self.provider = config.AI_PROVIDER
        self.model = ""
        self.client = None
        self._init_provider(self.provider)

    def _init_provider(self, provider: str):
        self.provider = provider
        init_map = {
            "openai": self._init_openai,
            "claude": self._init_claude,
            "groq": self._init_groq,
            "gemini": self._init_gemini,
            "ollama": self._init_ollama,
        }
        fn = init_map.get(provider)
        if fn:
            fn()
        else:
            raise ValueError(f"Unknown provider: {provider}")

    def switch_provider(self, provider: str) -> dict:
        try:
            self._init_provider(provider)
            return {"success": True, "provider": provider}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _init_openai(self):
        from openai import OpenAI
        self.client = OpenAI(api_key=config.OPENAI_API_KEY)
        self.model = config.OPENAI_MODEL

    def _init_claude(self):
        from anthropic import Anthropic
        self.client = Anthropic(api_key=config.CLAUDE_API_KEY)
        self.model = config.CLAUDE_MODEL

    def _init_groq(self):
        from groq import Groq
        self.client = Groq(api_key=config.GROQ_API_KEY)
        self.model = config.GROQ_MODEL

    def _init_gemini(self):
        import google.generativeai as genai
        genai.configure(api_key=config.GEMINI_API_KEY)
        self.client = genai.GenerativeModel(config.GEMINI_MODEL)
        self.model = config.GEMINI_MODEL

    def _init_ollama(self):
        import ollama as ollama_lib
        self.client = ollama_lib.Client(host=config.OLLAMA_HOST)
        self.model = config.OLLAMA_MODEL

    async def chat(self, user_message: str, image_base64: str | None = None,
                   sensor_context: str = "", memory_context: str = "") -> str:
        system_prompt = self.personality.get_system_prompt(sensor_context)
        if memory_context:
            system_prompt += f"\n\nHAL YANG KAMU INGAT TENTANG USER:\n{memory_context}"

        chat_map = {
            "openai": self._chat_openai,
            "claude": self._chat_claude,
            "groq": self._chat_groq,
            "gemini": self._chat_gemini,
            "ollama": self._chat_ollama,
        }
        fn = chat_map.get(self.provider)
        if not fn:
            return "Provider tidak tersedia."

        try:
            # Run blocking AI calls in thread pool to avoid blocking event loop
            return await asyncio.to_thread(fn, system_prompt, user_message, image_base64)
        except Exception as e:
            return f"Error dari {self.provider}: {e}"

    def _chat_openai(self, system_prompt, msg, img=None) -> str:
        messages = [{"role": "system", "content": system_prompt}]
        if img:
            content = [
                {"type": "text", "text": msg},
                {"type": "image_url", "image_url": {
                    "url": f"data:image/jpeg;base64,{img}", "detail": "low"}}
            ]
            messages.append({"role": "user", "content": content})
        else:
            messages.append({"role": "user", "content": msg})
        r = self.client.chat.completions.create(
            model=self.model, messages=messages, max_tokens=500, temperature=0.8)
        return r.choices[0].message.content

    def _chat_claude(self, system_prompt, msg, img=None) -> str:
        messages = []
        if img:
            content = [
                {"type": "image", "source": {
                    "type": "base64", "media_type": "image/jpeg", "data": img}},
                {"type": "text", "text": msg}
            ]
            messages.append({"role": "user", "content": content})
        else:
            messages.append({"role": "user", "content": msg})
        r = self.client.messages.create(
            model=self.model, max_tokens=500, system=system_prompt,
            messages=messages, temperature=0.8)
        return r.content[0].text

    def _chat_groq(self, system_prompt, msg, img=None) -> str:
        messages = [{"role": "system", "content": system_prompt}]
        if img:
            msg += "\n(gambar dikirim tapi model ini tidak support vision)"
        messages.append({"role": "user", "content": msg})
        r = self.client.chat.completions.create(
            model=self.model, messages=messages, max_tokens=500, temperature=0.8)
        return r.choices[0].message.content

    def _chat_gemini(self, system_prompt, msg, img=None) -> str:
        import google.generativeai as genai
        full_prompt = f"{system_prompt}\n\nUSER: {msg}\n\nA:"
        if img:
            image_bytes = base64.b64decode(img)
            image_part = {"mime_type": "image/jpeg", "data": image_bytes}
            r = self.client.generate_content(
                [full_prompt, image_part],
                generation_config=genai.types.GenerationConfig(
                    max_output_tokens=500, temperature=0.8))
        else:
            r = self.client.generate_content(
                full_prompt,
                generation_config=genai.types.GenerationConfig(
                    max_output_tokens=500, temperature=0.8))
        return r.text

    def _chat_ollama(self, system_prompt, msg, img=None) -> str:
        messages = [{"role": "system", "content": system_prompt}]
        if img:
            messages.append({"role": "user", "content": msg, "images": [img]})
        else:
            messages.append({"role": "user", "content": msg})
        r = self.client.chat(model=self.model, messages=messages,
                             options={"temperature": 0.8, "num_predict": 500})
        # Handle both dict and object response formats
        if isinstance(r, dict):
            return r["message"]["content"]
        return r.message.content

    def extract_actions(self, response: str) -> list[dict]:
        actions = []
        for match in re.findall(r'\[ACTION:\s*({.*?})\]', response, re.DOTALL):
            try:
                actions.append(json.loads(match))
            except json.JSONDecodeError:
                continue
        return actions

    def clean_response(self, response: str) -> str:
        return re.sub(r'\[ACTION:\s*{.*?}\]', '', response, flags=re.DOTALL).strip()

    def get_provider_info(self) -> dict:
        return {
            "provider": self.provider,
            "model": self.model,
            "vision_support": self.provider in ["openai", "claude", "gemini", "ollama"],
        }
