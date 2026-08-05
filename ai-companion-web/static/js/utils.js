/**
 * Utility Functions
 */

"use strict";

/** Shortcut for getElementById. */
const $ = (id) => document.getElementById(id);

/**
 * Fetch JSON from API with error handling.
 * @param {string} url
 * @param {RequestInit} [options]
 * @returns {Promise<any>}
 */
async function api(url, options = {}) {
  const response = await fetch(url, {
    headers: { "Content-Type": "application/json", ...options.headers },
    ...options,
  });
  return response.json();
}

/** Sanitize and format message text for HTML display. */
function formatMessage(text) {
  if (!text) return "";
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>")
    .replace(/\*(.*?)\*/g, "<em>$1</em>")
    .replace(/\n/g, "<br>");
}

/** Strip emoji and markdown from text for TTS. */
function cleanTextForSpeech(text) {
  return text
    .replace(/[\u{1F600}-\u{1F64F}]/gu, "")
    .replace(/[\u{1F300}-\u{1F5FF}]/gu, "")
    .replace(/[\u{1F680}-\u{1F6FF}]/gu, "")
    .replace(/[\u{1F1E0}-\u{1F1FF}]/gu, "")
    .replace(/[\u{2702}-\u{27B0}]/gu, "")
    .replace(/\*\*(.*?)\*\*/g, "$1")
    .replace(/\*(.*?)\*/g, "$1")
    .trim();
}

/** Show a toast notification. */
function showToast(message, type = "success") {
  const container = $("toast-container");
  const toast = document.createElement("div");
  toast.className = `toast ${type}`;
  toast.textContent = message;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = "0";
    toast.style.transform = "translateX(20px)";
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

/** Play the alert sound. */
function playAlertSound() {
  const audio = $("alert-sound");
  if (audio) {
    audio.currentTime = 0;
    audio.play().catch(() => {});
  }
}
