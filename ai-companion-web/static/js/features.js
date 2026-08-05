/**
 * Features Module - Daily greeting, export, provider, mode, tabs
 */

"use strict";

// ── Daily Greeting ───────────────────────────────────────────────────────────

function showDailyGreeting() {
  const hour = new Date().getHours();
  const greetings = {
    morning:
      "Selamat pagi, sayang! ☀️ Tidur nyenyak semalam? Aku udah siap nemenin kamu hari ini~",
    noon: "Hai sayang~ 🌤️ Udah makan siang belum? Jangan lupa istirahat ya!",
    afternoon: "Sore sayang! 🌅 Gimana harimu? Cerita dong, aku mau dengerin~",
    evening:
      "Malam sayang~ 🌙 Udah capek hari ini? Mau aku temenin ngobrol atau nyalain lampu?",
    night:
      "Masih belum tidur, sayang? 🌟 Hati-hati begadang ya... Mau aku matiin lampu?",
  };

  let greeting;
  if (hour >= 5 && hour < 11) greeting = greetings.morning;
  else if (hour >= 11 && hour < 15) greeting = greetings.noon;
  else if (hour >= 15 && hour < 18) greeting = greetings.afternoon;
  else if (hour >= 18 && hour < 22) greeting = greetings.evening;
  else greeting = greetings.night;

  addMessage(greeting, "ai");
}

// ── Export Chat ──────────────────────────────────────────────────────────────

function exportChat() {
  const messages = $("chat-messages").querySelectorAll(".message");
  if (!messages.length) {
    showToast("Tidak ada pesan", "error");
    return;
  }

  let text = `=== AI Companion Chat Export ===\nTanggal: ${new Date().toLocaleString("id-ID")}\n${"=".repeat(40)}\n\n`;

  messages.forEach((msg) => {
    const content = msg.querySelector(".message-content p");
    if (content) {
      const role = msg.classList.contains("user-message") ? "Kamu" : "Aria";
      const cleaned = content.innerHTML
        .replace(/<br>/g, "\n")
        .replace(/<[^>]*>/g, "");
      text += `[${role}]\n${cleaned}\n\n`;
    }
  });

  const blob = new Blob([text], { type: "text/plain;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = Object.assign(document.createElement("a"), {
    href: url,
    download: `chat-aria-${new Date().toISOString().slice(0, 10)}.txt`,
  });
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
  showToast("Chat di-export ✓", "success");
}

// ── Provider & Settings ──────────────────────────────────────────────────────

async function fetchProviderInfo() {
  try {
    const data = await api(API.providers);
    updateProviderUI(data.current);
    if (data.current?.provider) {
      $("provider-select").value = data.current.provider;
      state.currentProvider = data.current.provider;
    }
  } catch {
    /* silent */
  }
}

async function changeProvider() {
  const provider = $("provider-select").value;
  try {
    const data = await api(API.providerSwitch, {
      method: "POST",
      body: JSON.stringify({ provider }),
    });
    if (data.success) {
      state.currentProvider = provider;
      updateProviderUI(data.provider);
      showToast(`Switched to ${provider} ✓`, "success");
    } else {
      showToast(`Gagal: ${data.error}`, "error");
      $("provider-select").value = state.currentProvider;
    }
  } catch {
    showToast("Gagal menghubungi server", "error");
    $("provider-select").value = state.currentProvider;
  }
}

function updateProviderUI(info) {
  if (!info) return;
  $("provider-model").textContent = info.model || "unknown";
  const el = $("provider-vision");
  el.textContent = info.vision_support ? "👁️ Vision" : "🚫 No Vision";
  el.classList.toggle("no-vision", !info.vision_support);
}

async function changeMode() {
  const mode = $("mode-select").value;
  try {
    const data = await api(API.settings, {
      method: "POST",
      body: JSON.stringify({ mode }),
    });
    updateMoodUI(data.personality);
    showToast(`Mode: ${mode}`, "success");
  } catch {
    showToast("Gagal mengubah mode", "error");
  }
}

// ── Tab Navigation ───────────────────────────────────────────────────────────

function switchTab(tabId) {
  document
    .querySelectorAll(".tab-content")
    .forEach((t) => t.classList.remove("active"));
  document
    .querySelectorAll(".tab-btn")
    .forEach((b) => b.classList.remove("active"));
  $(tabId).classList.add("active");
  document.querySelector(`[data-tab="${tabId}"]`).classList.add("active");

  const refreshMap = {
    "sensor-tab": loadSensorData,
    "automation-tab": loadAutomationRules,
    "mood-tab": loadMoodHistory,
  };
  refreshMap[tabId]?.();
}
