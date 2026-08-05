"""
Automation Rules Engine - Condition-based smart home automation.
Rules trigger actions based on sensor thresholds and conditions.
"""

import json
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional


RULES_FILE = Path(__file__).parent / "automation_rules.json"


class AutomationRule:
    """A single automation rule."""

    def __init__(self, rule_id: str, name: str, condition_type: str,
                 sensor: str, operator: str, threshold: float,
                 actions: list[dict], enabled: bool = True,
                 cooldown_minutes: int = 5, notify: bool = True):
        self.id = rule_id
        self.name = name
        self.condition_type = condition_type  # "sensor_threshold", "alarm_active"
        self.sensor = sensor  # "gas_ppm", "power", "fire", "voltage", "current"
        self.operator = operator  # ">", "<", ">=", "<=", "==", "!="
        self.threshold = threshold
        self.actions = actions  # [{"target": "...", "state": "on/off"}]
        self.enabled = enabled
        self.cooldown_minutes = cooldown_minutes
        self.notify = notify
        self.last_triggered: Optional[str] = None
        self.trigger_count: int = 0

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "condition_type": self.condition_type,
            "sensor": self.sensor,
            "operator": self.operator,
            "threshold": self.threshold,
            "actions": self.actions,
            "enabled": self.enabled,
            "cooldown_minutes": self.cooldown_minutes,
            "notify": self.notify,
            "last_triggered": self.last_triggered,
            "trigger_count": self.trigger_count,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "AutomationRule":
        rule = cls(
            rule_id=data["id"],
            name=data["name"],
            condition_type=data.get("condition_type", "sensor_threshold"),
            sensor=data["sensor"],
            operator=data["operator"],
            threshold=data["threshold"],
            actions=data["actions"],
            enabled=data.get("enabled", True),
            cooldown_minutes=data.get("cooldown_minutes", 5),
            notify=data.get("notify", True),
        )
        rule.last_triggered = data.get("last_triggered")
        rule.trigger_count = data.get("trigger_count", 0)
        return rule

    def check_condition(self, sensor_value: float) -> bool:
        """Check if the condition is met."""
        ops = {
            ">": lambda a, b: a > b,
            "<": lambda a, b: a < b,
            ">=": lambda a, b: a >= b,
            "<=": lambda a, b: a <= b,
            "==": lambda a, b: a == b,
            "!=": lambda a, b: a != b,
        }
        op_fn = ops.get(self.operator)
        if not op_fn:
            return False
        return op_fn(sensor_value, self.threshold)

    def is_in_cooldown(self) -> bool:
        """Check if rule is still in cooldown period."""
        if not self.last_triggered:
            return False
        last = datetime.fromisoformat(self.last_triggered)
        now = datetime.now(timezone.utc)
        diff = (now - last).total_seconds() / 60
        return diff < self.cooldown_minutes


class AutomationEngine:
    """Manages automation rules and evaluates them against sensor data."""

    def __init__(self, smart_home_controller):
        self.controller = smart_home_controller
        self.rules: list[AutomationRule] = []
        self.notifications: list[dict] = []  # In-memory notification queue
        self._load_rules()

    def _load_rules(self):
        """Load rules from JSON file."""
        if RULES_FILE.exists():
            try:
                with open(RULES_FILE, "r") as f:
                    data = json.load(f)
                self.rules = [AutomationRule.from_dict(r) for r in data]
            except (json.JSONDecodeError, KeyError):
                self.rules = self._get_default_rules()
                self._save_rules()
        else:
            self.rules = self._get_default_rules()
            self._save_rules()

    def _save_rules(self):
        """Persist rules to JSON file."""
        with open(RULES_FILE, "w") as f:
            json.dump([r.to_dict() for r in self.rules], f, indent=2)

    def _get_default_rules(self) -> list[AutomationRule]:
        """Default safety rules."""
        return [
            AutomationRule(
                rule_id="rule_gas_high",
                name="Gas Bocor - Matikan Semua",
                condition_type="sensor_threshold",
                sensor="gas_ppm",
                operator=">",
                threshold=500,
                actions=[
                    {"target": "kamar tidur", "state": "off"},
                    {"target": "ruang tamu", "state": "off"},
                    {"target": "kamar mandi", "state": "off"},
                    {"target": "dapur", "state": "off"},
                ],
                cooldown_minutes=10,
                notify=True,
            ),
            AutomationRule(
                rule_id="rule_fire_detected",
                name="Api Terdeteksi - Emergency",
                condition_type="sensor_threshold",
                sensor="fire",
                operator="==",
                threshold=1,
                actions=[
                    {"target": "kamar tidur", "state": "off"},
                    {"target": "ruang tamu", "state": "off"},
                    {"target": "kamar mandi", "state": "off"},
                    {"target": "dapur", "state": "off"},
                ],
                cooldown_minutes=5,
                notify=True,
            ),
            AutomationRule(
                rule_id="rule_power_high",
                name="Daya Tinggi - Peringatan",
                condition_type="sensor_threshold",
                sensor="power",
                operator=">",
                threshold=1000,
                actions=[],
                cooldown_minutes=15,
                notify=True,
            ),
        ]

    def evaluate(self, sensor_data: dict) -> list[dict]:
        """
        Evaluate all rules against current sensor data.
        Returns list of triggered actions and notifications.
        """
        results = []

        for rule in self.rules:
            if not rule.enabled:
                continue
            if rule.is_in_cooldown():
                continue

            # Get sensor value
            value = self._get_sensor_value(rule.sensor, sensor_data)
            if value is None:
                continue

            if rule.check_condition(value):
                # Rule triggered
                rule.last_triggered = datetime.now(timezone.utc).isoformat()
                rule.trigger_count += 1

                # Execute actions
                action_results = []
                for action in rule.actions:
                    result = self.controller.send_command(
                        action["target"], action["state"],
                        f"[Auto] {rule.name}"
                    )
                    action_results.append(result)

                # Create notification
                notification = {
                    "id": str(uuid.uuid4())[:8],
                    "rule_id": rule.id,
                    "rule_name": rule.name,
                    "sensor": rule.sensor,
                    "value": value,
                    "threshold": rule.threshold,
                    "actions_executed": len(rule.actions),
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "type": "danger" if rule.sensor in ["fire", "gas_ppm"] else "warning",
                }

                if rule.notify:
                    self.notifications.append(notification)
                    # Keep only last 50 notifications
                    if len(self.notifications) > 50:
                        self.notifications = self.notifications[-50:]

                results.append({
                    "rule": rule.to_dict(),
                    "notification": notification,
                    "action_results": action_results,
                })

        self._save_rules()
        return results

    def _get_sensor_value(self, sensor: str, data: dict) -> Optional[float]:
        """Extract sensor value from data dict."""
        if sensor == "gas_ppm":
            gas = data.get("gas")
            if gas:
                return float(gas.get("gasPpm", 0))
        elif sensor == "power":
            energy = data.get("energy")
            if energy:
                return float(energy.get("power", 0))
        elif sensor == "voltage":
            energy = data.get("energy")
            if energy:
                return float(energy.get("voltage", 0))
        elif sensor == "current":
            energy = data.get("energy")
            if energy:
                return float(energy.get("current", 0))
        elif sensor == "fire":
            fire = data.get("fire")
            if fire:
                return 1.0 if fire.get("flameDetected") else 0.0
        return None

    def add_rule(self, name: str, sensor: str, operator: str, threshold: float,
                 actions: list[dict], cooldown_minutes: int = 5,
                 notify: bool = True) -> AutomationRule:
        """Add a new automation rule."""
        rule = AutomationRule(
            rule_id=f"rule_{uuid.uuid4().hex[:8]}",
            name=name,
            condition_type="sensor_threshold",
            sensor=sensor,
            operator=operator,
            threshold=threshold,
            actions=actions,
            cooldown_minutes=cooldown_minutes,
            notify=notify,
        )
        self.rules.append(rule)
        self._save_rules()
        return rule

    def remove_rule(self, rule_id: str) -> bool:
        """Remove a rule by ID."""
        before = len(self.rules)
        self.rules = [r for r in self.rules if r.id != rule_id]
        if len(self.rules) < before:
            self._save_rules()
            return True
        return False

    def toggle_rule(self, rule_id: str) -> Optional[bool]:
        """Toggle a rule's enabled state. Returns new state or None."""
        for rule in self.rules:
            if rule.id == rule_id:
                rule.enabled = not rule.enabled
                self._save_rules()
                return rule.enabled
        return None

    def get_all_rules(self) -> list[dict]:
        """Get all rules as dicts."""
        return [r.to_dict() for r in self.rules]

    def get_notifications(self, limit: int = 20) -> list[dict]:
        """Get recent notifications."""
        return self.notifications[-limit:]

    def clear_notifications(self):
        """Clear all notifications."""
        self.notifications = []
