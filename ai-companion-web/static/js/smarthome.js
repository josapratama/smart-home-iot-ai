/**
 * Smart Home Module - Relay control, scenes
 */

"use strict";

async function toggleRelay(item) {
  const target = item.dataset.target;
  const newState = item.classList.contains("on") ? "off" : "on";

  try {
    const data = await api(API.smartHomeCommand, {
      method: "POST",
      body: JSON.stringify({ target, state: newState }),
    });
    if (data.success) {
      item.classList.toggle("on");
      item.querySelector(".relay-icon").textContent =
        newState === "on" ? "💡" : "🌙";
      showToast(data.message, "success");
    } else {
      showToast(data.message || "Gagal", "error");
    }
  } catch {
    showToast("Gagal mengirim command", "error");
  }
}

async function executeScene(sceneId) {
  try {
    const data = await api(`${API.scenes}/${sceneId}`, { method: "POST" });
    showToast(data.message || "Done", data.success ? "success" : "error");
  } catch {
    showToast("Gagal menjalankan scene", "error");
  }
}
