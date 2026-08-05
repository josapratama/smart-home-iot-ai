/**
 * Mood & Personality Module - Mood display, history, personality settings
 */

"use strict";

async function fetchMood() {
  try {
    updateMoodUI(await api(API.mood));
  } catch {
    /* silent */
  }
}

function updateMoodUI(mood) {
  if (!mood) return;
  const emoji = MOOD_EMOJIS[mood.mood] || "🙂";

  $("mood-badge").textContent = `${emoji} ${mood.mood}`;
  $("companion-name").textContent = mood.name || "Aria";
  $("affection-bar").style.width = `${mood.affection_level}%`;
  $("affection-val").textContent = mood.affection_level;
  $("patience-bar").style.width = `${mood.patience_level}%`;
  $("patience-val").textContent = mood.patience_level;

  // Mood tab stats
  $("mood-big-emoji").textContent = emoji;
  $("mood-big-label").textContent = mood.mood;
  $("mood-total-chats").textContent = mood.conversation_count || 0;
  $("mood-affection-big").textContent = mood.affection_level;
  $("mood-patience-big").textContent = mood.patience_level;

  // Avatar color
  $("avatar").style.background =
    AVATAR_COLORS[mood.mood] || "linear-gradient(135deg, #a855f7, #6366f1)";

  if (mood.mode) $("mode-select").value = mood.mode;
  populatePersonalitySettings(mood);
}

async function loadMoodHistory() {
  try {
    renderMoodHistory(await api(API.moodHistory));
  } catch {
    /* silent */
  }
}

function renderMoodHistory(history) {
  const container = $("mood-history-list");
  if (!history?.length) {
    container.innerHTML = '<p class="empty-state">Belum ada mood history</p>';
    return;
  }

  container.innerHTML = history
    .slice(-30)
    .reverse()
    .map((item) => {
      const emoji = MOOD_EMOJIS[item.mood] || "🙂";
      const time = item.timestamp
        ? new Date(item.timestamp).toLocaleString("id-ID", {
            hour: "2-digit",
            minute: "2-digit",
            day: "numeric",
            month: "short",
          })
        : "";
      return `
      <div class="mood-history-item">
        <span class="mood-history-emoji">${emoji}</span>
        <div class="mood-history-info">
          <span>${item.mood}</span>
          <span class="mood-history-trigger">trigger: ${item.trigger || "-"}</span>
        </div>
        <span class="mood-history-time">${time}</span>
      </div>`;
    })
    .join("");
}

// ── Personality Settings ─────────────────────────────────────────────────────

async function savePersonalitySettings() {
  const body = {
    user_nickname: $("setting-nickname").value.trim() || undefined,
    user_real_name: $("setting-realname").value.trim(),
    name: $("setting-ainame").value.trim() || undefined,
    love_language: $("setting-lovelang").value || undefined,
  };
  try {
    const data = await api(API.settings, {
      method: "POST",
      body: JSON.stringify(body),
    });
    if (data.success) {
      showToast("Settings disimpan ✓", "success");
      updateMoodUI(data.personality);
    }
  } catch {
    showToast("Gagal menyimpan", "error");
  }
}

function populatePersonalitySettings(mood) {
  if (!mood) return;
  if (mood.user_nickname) $("setting-nickname").value = mood.user_nickname;
  if (mood.user_real_name) $("setting-realname").value = mood.user_real_name;
  if (mood.name) $("setting-ainame").value = mood.name;
  if (mood.love_language) $("setting-lovelang").value = mood.love_language;
}
