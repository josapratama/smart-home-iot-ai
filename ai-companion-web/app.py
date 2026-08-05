"""
AI Companion Web - FastAPI Backend v3
Features: multi-provider, memory, scheduler, sensor, scenes, automation,
           conversation history, rate limiting, notifications, image upload.
"""

import time
import base64
from collections import defaultdict
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, UploadFile, File, Query
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
import json

from config import config
from personality import Personality
from ai_brain import AIBrain
from smart_home_controller import SmartHomeController, db
from memory import Memory
from sensor_monitor import SensorMonitor
from scheduler import SchedulerModule
from automation import AutomationEngine

app = FastAPI(title="AI Companion", version="3.0.0")
app.mount("/static", StaticFiles(directory="static"), name="static")

# ── Initialize modules ─────────────────────────────────────────────────────────
personality = Personality(mode=config.COMPANION_MODE, name=config.COMPANION_NAME)
brain = AIBrain(personality)
smart_home = SmartHomeController()
memory = Memory(db, user_id="default")
sensor_monitor = SensorMonitor(db, config.HOME_ID)
scheduler = SchedulerModule(smart_home)
automation = AutomationEngine(smart_home)

# Load saved personality state
saved_state = memory.load_personality_state()
if saved_state:
    personality.load_from_dict(saved_state)

# ── Rate Limiting ──────────────────────────────────────────────────────────────
_rate_limit: dict[str, list[float]] = defaultdict(list)
RATE_LIMIT_MAX = 30  # max requests
RATE_LIMIT_WINDOW = 60  # per 60 seconds


def _check_rate_limit(client_id: str = "default") -> bool:
    """Returns True if rate limit exceeded."""
    now = time.time()
    window_start = now - RATE_LIMIT_WINDOW
    _rate_limit[client_id] = [t for t in _rate_limit[client_id] if t > window_start]
    if len(_rate_limit[client_id]) >= RATE_LIMIT_MAX:
        return True
    _rate_limit[client_id].append(now)
    return False


# ── Models ─────────────────────────────────────────────────────────────────────

class ChatMessage(BaseModel):
    message: str
    image: str | None = None


class SettingsUpdate(BaseModel):
    mode: str | None = None
    name: str | None = None
    custom_prompt: str | None = None
    user_nickname: str | None = None
    user_real_name: str | None = None
    love_language: str | None = None
    interests: list[str] | None = None


class ProviderSwitch(BaseModel):
    provider: str


class ScheduleRequest(BaseModel):
    target: str
    state: str
    delay_minutes: int | None = None
    hour: int | None = None
    minute: int | None = 0
    days: str | None = "mon-sun"
    reason: str = ""


class AutomationRuleRequest(BaseModel):
    name: str
    sensor: str
    operator: str
    threshold: float
    actions: list[dict] = []
    cooldown_minutes: int = 5
    notify: bool = True


class CommandRequest(BaseModel):
    target: str
    state: str


# ── Routes ─────────────────────────────────────────────────────────────────────

@app.get("/")
async def index():
    return FileResponse("static/index.html")


@app.post("/api/chat")
async def chat(msg: ChatMessage):
    if _check_rate_limit():
        return {"error": "Rate limit exceeded. Coba lagi nanti.", "response": "Sabar ya, terlalu banyak pesan. Tunggu sebentar~ 😅"}

    # Detect trigger and update mood
    trigger = _detect_trigger(msg.message)
    personality.update_mood(trigger)

    # Get contexts
    sensor_ctx = sensor_monitor.get_sensor_context()
    facts = memory.get_facts(limit=10)
    memory_ctx = "\n".join(f"- {f}" for f in facts) if facts else ""

    # Get AI response
    response = await brain.chat(msg.message, msg.image, sensor_ctx, memory_ctx)
    actions = brain.extract_actions(response)
    clean_text = brain.clean_response(response)

    # Revenge action
    revenge = personality.get_revenge_action()
    if revenge:
        actions.append(revenge)

    # Execute actions
    action_results = []
    for action in actions:
        result = _execute_action(action)
        if result:
            action_results.append(result)

    # Save to memory
    memory.save_message("user", msg.message, personality.mood.value)
    memory.save_message("assistant", clean_text, personality.mood.value)
    memory.save_personality_state(personality.to_dict())
    memory.save_mood_history(personality.mood.value, trigger)

    # Check automation rules with latest sensor data
    _check_automation()

    return {
        "response": clean_text,
        "mood": personality.to_dict(),
        "actions": action_results,
        "provider": brain.get_provider_info(),
    }


@app.post("/api/chat/image")
async def chat_with_image(file: UploadFile = File(...), message: str = Query("")):
    """Chat with uploaded image file."""
    if _check_rate_limit():
        return {"error": "Rate limit exceeded."}

    contents = await file.read()
    image_base64 = base64.b64encode(contents).decode("utf-8")

    trigger = _detect_trigger(message)
    personality.update_mood(trigger)

    sensor_ctx = sensor_monitor.get_sensor_context()
    facts = memory.get_facts(limit=10)
    memory_ctx = "\n".join(f"- {f}" for f in facts) if facts else ""

    prompt = message if message else "Lihat gambar ini dan deskripsikan apa yang kamu lihat."
    response = await brain.chat(prompt, image_base64, sensor_ctx, memory_ctx)
    actions = brain.extract_actions(response)
    clean_text = brain.clean_response(response)

    action_results = []
    for action in actions:
        result = _execute_action(action)
        if result:
            action_results.append(result)

    memory.save_message("user", f"[image] {message}", personality.mood.value)
    memory.save_message("assistant", clean_text, personality.mood.value)
    memory.save_personality_state(personality.to_dict())

    return {
        "response": clean_text,
        "mood": personality.to_dict(),
        "actions": action_results,
        "provider": brain.get_provider_info(),
    }


# ── Conversation History ───────────────────────────────────────────────────────

@app.get("/api/messages")
async def get_messages(limit: int = Query(50, ge=1, le=200)):
    """Get conversation history."""
    messages = memory.get_recent_messages(limit=limit)
    return {"messages": messages}


# ── Mood ───────────────────────────────────────────────────────────────────────

@app.get("/api/mood")
async def get_mood():
    return personality.to_dict()


@app.get("/api/mood/history")
async def get_mood_history():
    return memory.get_mood_history(limit=50)


@app.post("/api/settings")
async def update_settings(settings: SettingsUpdate):
    if settings.mode and settings.mode in ["teman", "pacar"]:
        personality.mode = settings.mode
        # Update default nickname based on mode
        if settings.mode == "pacar" and personality.user_nickname in ["Bro", "Dude", "Woi"]:
            personality.user_nickname = "Sayang"
        elif settings.mode == "teman" and personality.user_nickname in ["Sayang", "Beb", "Cinta"]:
            personality.user_nickname = "Bro"
    if settings.name:
        personality.name = settings.name
    if settings.custom_prompt is not None:
        personality.custom_prompt = settings.custom_prompt
    if settings.user_nickname:
        personality.user_nickname = settings.user_nickname
    if settings.user_real_name is not None:
        personality.user_real_name = settings.user_real_name
    if settings.love_language and settings.love_language in ["words", "acts", "gifts", "time", "touch"]:
        personality.love_language = settings.love_language
    if settings.interests:
        personality.interests = settings.interests
    memory.save_personality_state(personality.to_dict())
    return {"success": True, "personality": personality.to_dict()}


# ── Provider ───────────────────────────────────────────────────────────────────

@app.get("/api/providers")
async def get_providers():
    return {
        "current": brain.get_provider_info(),
        "available": config.AVAILABLE_PROVIDERS,
    }


@app.post("/api/providers/switch")
async def switch_provider(data: ProviderSwitch):
    result = brain.switch_provider(data.provider)
    if result["success"]:
        return {"success": True, "provider": brain.get_provider_info()}
    return {"success": False, "error": result["error"]}


# ── Smart Home ─────────────────────────────────────────────────────────────────

@app.get("/api/smart-home/status")
async def get_smart_home_status():
    return smart_home.get_device_status()


@app.get("/api/smart-home/relays")
async def get_relay_states():
    return smart_home.get_all_relay_states()


@app.post("/api/smart-home/command")
async def send_command(cmd: CommandRequest):
    return smart_home.send_command(cmd.target, cmd.state, "manual web UI")


@app.get("/api/smart-home/scenes")
async def get_scenes():
    return config.SCENES


@app.post("/api/smart-home/scenes/{scene_id}")
async def execute_scene(scene_id: str):
    return smart_home.execute_scene(scene_id)


# ── Sensors ────────────────────────────────────────────────────────────────────

@app.get("/api/sensors")
async def get_sensors():
    try:
        return sensor_monitor.get_sensor_summary_for_api()
    except Exception:
        return {"energy": None, "gas": None, "fire": None, "alarms": [], "energy_today": {"avg_power": 0, "max_power": 0, "readings_count": 0}}


# ── Scheduler ──────────────────────────────────────────────────────────────────

@app.get("/api/schedules")
async def get_schedules():
    return scheduler.get_all_jobs()


@app.post("/api/schedules")
async def add_schedule(req: ScheduleRequest):
    if req.delay_minutes:
        job = scheduler.add_delay(req.target, req.state, req.delay_minutes, req.reason)
    elif req.hour is not None:
        job = scheduler.add_recurring(req.target, req.state, req.hour,
                                      req.minute or 0, req.days or "mon-sun", req.reason)
    else:
        return {"success": False, "message": "Specify delay_minutes or hour"}
    return {"success": True, "job": job}


@app.delete("/api/schedules/{job_id}")
async def remove_schedule(job_id: str):
    ok = scheduler.remove_job(job_id)
    return {"success": ok}


# ── Automation Rules ───────────────────────────────────────────────────────────

@app.get("/api/automation/rules")
async def get_automation_rules():
    return automation.get_all_rules()


@app.post("/api/automation/rules")
async def add_automation_rule(req: AutomationRuleRequest):
    rule = automation.add_rule(
        name=req.name,
        sensor=req.sensor,
        operator=req.operator,
        threshold=req.threshold,
        actions=req.actions,
        cooldown_minutes=req.cooldown_minutes,
        notify=req.notify,
    )
    return {"success": True, "rule": rule.to_dict()}


@app.delete("/api/automation/rules/{rule_id}")
async def remove_automation_rule(rule_id: str):
    ok = automation.remove_rule(rule_id)
    return {"success": ok}


@app.post("/api/automation/rules/{rule_id}/toggle")
async def toggle_automation_rule(rule_id: str):
    new_state = automation.toggle_rule(rule_id)
    if new_state is None:
        return {"success": False, "message": "Rule not found"}
    return {"success": True, "enabled": new_state}


@app.get("/api/automation/notifications")
async def get_automation_notifications():
    return automation.get_notifications()


@app.delete("/api/automation/notifications")
async def clear_automation_notifications():
    automation.clear_notifications()
    return {"success": True}


# ── Memory ─────────────────────────────────────────────────────────────────────

@app.get("/api/memory/facts")
async def get_facts():
    return memory.get_facts()


@app.post("/api/memory/facts")
async def add_fact(fact: str = Query(...)):
    memory.save_fact(fact)
    return {"success": True}


# ── WebSocket ──────────────────────────────────────────────────────────────────

@app.websocket("/ws/chat")
async def websocket_chat(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            msg = json.loads(data)
            user_message = msg.get("message", "")
            image_base64 = msg.get("image")

            trigger = _detect_trigger(user_message)
            personality.update_mood(trigger)

            sensor_ctx = sensor_monitor.get_sensor_context()
            facts = memory.get_facts(limit=10)
            memory_ctx = "\n".join(f"- {f}" for f in facts) if facts else ""

            try:
                response = await brain.chat(user_message, image_base64, sensor_ctx, memory_ctx)
                actions = brain.extract_actions(response)
                clean_text = brain.clean_response(response)
            except Exception as e:
                clean_text = f"Maaf, terjadi error: {str(e)}"
                actions = []

            revenge = personality.get_revenge_action()
            if revenge:
                actions.append(revenge)

            action_results = []
            for action in actions:
                result = _execute_action(action)
                if result:
                    action_results.append(result)

            memory.save_message("user", user_message, personality.mood.value)
            memory.save_message("assistant", clean_text, personality.mood.value)
            memory.save_personality_state(personality.to_dict())
            memory.save_mood_history(personality.mood.value, trigger)

            await websocket.send_text(json.dumps({
                "response": clean_text,
                "mood": personality.to_dict(),
                "actions": action_results,
                "provider": brain.get_provider_info(),
            }))
    except WebSocketDisconnect:
        pass
    except Exception:
        try:
            await websocket.close()
        except Exception:
            pass


# ── Helpers ────────────────────────────────────────────────────────────────────

def _detect_trigger(message: str) -> str:
    msg = message.lower()
    sweet = ["sayang", "cinta", "love", "cantik", "manis", "kangen", "rindu", "makasih"]
    rude = ["bodoh", "goblok", "tolol", "bego", "anjing", "bangsat", "diam", "berisik"]
    compliment = ["pintar", "hebat", "keren", "bagus", "good", "smart", "cantik", "lucu"]
    apology = ["maaf", "sorry", "maafin", "ampun", "salah aku"]
    goodnight = ["selamat tidur", "good night", "tidur dulu", "mau tidur", "ngantuk",
                 "bobo", "nite", "met tidur"]
    jealousy_names = ["cewek", "pacar", "mantan", "gebetan", "selingkuh", "dia siapa",
                      "temen cewe", "kenalan baru"]

    if any(w in msg for w in apology):
        return "apologized"
    if any(w in msg for w in goodnight):
        return "goodnight"
    if any(w in msg for w in jealousy_names):
        return "jealousy"
    if any(w in msg for w in sweet):
        return "sweet"
    if any(w in msg for w in rude):
        return "rude"
    if any(w in msg for w in compliment):
        return "complimented"
    return "normal"


def _execute_action(action: dict) -> dict | None:
    action_type = action.get("type")

    if action_type == "relay":
        return smart_home.send_command(
            action.get("target", ""), action.get("state", "off"),
            action.get("reason", ""))

    elif action_type == "scene":
        return smart_home.execute_scene(action.get("scene", ""))

    elif action_type == "schedule":
        delay = action.get("delay_minutes", 0)
        if delay:
            job = scheduler.add_delay(
                action.get("target", ""), action.get("state", "off"),
                delay, action.get("reason", ""))
            return {"success": True, "message": f"Dijadwalkan {delay} menit lagi", "job": job}

    return None


def _check_automation():
    """Check automation rules against current sensor data."""
    try:
        sensor_data = sensor_monitor.get_sensor_summary_for_api()
        automation.evaluate(sensor_data)
    except Exception:
        pass  # Don't let automation errors break chat


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
