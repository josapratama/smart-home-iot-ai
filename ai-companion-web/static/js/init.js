/**
 * App Initialization - Event listeners & startup
 * This file should be loaded LAST.
 */

"use strict";

document.addEventListener("DOMContentLoaded", () => {
  // ── Chat Input ─────────────────────────────────────────────────────────────
  $("chat-input").addEventListener("keydown", (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  });
  $("send-btn").addEventListener("click", () => sendMessage());
  $("camera-snap-btn").addEventListener("click", () => sendMessage(true));

  // ── Controls ───────────────────────────────────────────────────────────────
  $("camera-toggle").addEventListener("click", toggleCamera);
  $("voice-toggle").addEventListener("click", toggleVoice);
  $("handsfree-btn").addEventListener("click", toggleHandsFree);
  $("mode-select").addEventListener("change", changeMode);
  $("provider-select").addEventListener("change", changeProvider);

  // ── Voice & Image ──────────────────────────────────────────────────────────
  $("mic-btn").addEventListener("click", toggleMic);
  $("image-upload-btn").addEventListener("click", () =>
    $("image-file-input").click(),
  );
  $("image-file-input").addEventListener("change", (e) => {
    if (e.target.files[0]) {
      sendImageFile(e.target.files[0]);
      e.target.value = "";
    }
  });

  // ── Smart Home ─────────────────────────────────────────────────────────────
  document
    .querySelectorAll(".relay-item")
    .forEach((item) => item.addEventListener("click", () => toggleRelay(item)));
  document
    .querySelectorAll(".scene-btn")
    .forEach((btn) =>
      btn.addEventListener("click", () => executeScene(btn.dataset.scene)),
    );

  // ── Tabs ───────────────────────────────────────────────────────────────────
  document
    .querySelectorAll(".tab-btn")
    .forEach((btn) =>
      btn.addEventListener("click", () => switchTab(btn.dataset.tab)),
    );

  // ── Quick Replies ──────────────────────────────────────────────────────────
  document.querySelectorAll(".quick-reply-btn[data-msg]").forEach((btn) => {
    btn.addEventListener("click", () => {
      $("chat-input").value = btn.dataset.msg;
      sendMessage();
    });
  });

  // ── Automation & Settings ──────────────────────────────────────────────────
  $("add-rule-btn").addEventListener("click", addAutomationRule);
  $("clear-notif-btn").addEventListener("click", clearNotifications);
  $("export-chat-btn").addEventListener("click", exportChat);
  $("save-personality-btn").addEventListener("click", savePersonalitySettings);

  // ── Drag & Drop Image ──────────────────────────────────────────────────────
  const chat = $("chat-messages");
  chat.addEventListener("dragover", (e) => e.preventDefault());
  chat.addEventListener("drop", (e) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (file?.type.startsWith("image/")) sendImageFile(file);
  });

  // ── Load Voices ────────────────────────────────────────────────────────────
  if ("speechSynthesis" in window) speechSynthesis.getVoices();

  // ── Load Initial Data ──────────────────────────────────────────────────────
  Promise.all([
    fetchMood(),
    fetchProviderInfo(),
    loadConversationHistory(),
    loadSensorData(),
    loadAutomationRules(),
    loadMoodHistory(),
    loadNotifications(),
  ]).then(() => {
    if (!$("chat-messages").children.length) showDailyGreeting();
  });

  // ── Start Polling ──────────────────────────────────────────────────────────
  state.pollingIds.sensors = setInterval(
    loadSensorData,
    POLLING_INTERVALS.sensors,
  );
  state.pollingIds.notifications = setInterval(
    loadNotifications,
    POLLING_INTERVALS.notifications,
  );
});
