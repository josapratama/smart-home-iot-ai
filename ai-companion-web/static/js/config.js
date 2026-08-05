/**
 * Configuration & Constants
 */

"use strict";

const API = {
  chat: "/api/chat",
  chatImage: "/api/chat/image",
  messages: "/api/messages",
  mood: "/api/mood",
  moodHistory: "/api/mood/history",
  settings: "/api/settings",
  providers: "/api/providers",
  providerSwitch: "/api/providers/switch",
  smartHomeCommand: "/api/smart-home/command",
  scenes: "/api/smart-home/scenes",
  sensors: "/api/sensors",
  automationRules: "/api/automation/rules",
  automationNotifications: "/api/automation/notifications",
};

const MOOD_EMOJIS = {
  happy: "😊",
  neutral: "🙂",
  sad: "😢",
  angry: "😤",
  flirty: "😘",
  worried: "😟",
  playful: "😜",
  jealous: "😒",
  clingy: "🥺",
  sleepy: "😴",
};

const AVATAR_COLORS = {
  angry: "linear-gradient(135deg, #ef4444, #dc2626)",
  happy: "linear-gradient(135deg, #ff6b9d, #a855f7)",
  flirty: "linear-gradient(135deg, #ff6b9d, #a855f7)",
  sad: "linear-gradient(135deg, #3b82f6, #6366f1)",
  worried: "linear-gradient(135deg, #f97316, #eab308)",
  playful: "linear-gradient(135deg, #22c55e, #3b82f6)",
  jealous: "linear-gradient(135deg, #f97316, #ef4444)",
  clingy: "linear-gradient(135deg, #ff6b9d, #ec4899)",
  sleepy: "linear-gradient(135deg, #6366f1, #4338ca)",
};

const POLLING_INTERVALS = { sensors: 30000, notifications: 15000 };
const HANDSFREE_RESTART_DELAY = 500;
