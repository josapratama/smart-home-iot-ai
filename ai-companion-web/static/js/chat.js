/**
 * Chat Module - Message sending, display, history, image upload
 */

"use strict";

/** Add a message bubble to the chat area. */
function addMessage(text, type, animate = true, responseTime = null) {
  const container = $("chat-messages");
  const div = document.createElement("div");
  div.className = `message ${type}-message`;
  if (!animate) div.style.animation = "none";

  const avatar = type === "ai" ? "🤖" : "👤";
  const timeHtml =
    responseTime && type === "ai"
      ? `<div class="response-time">⚡ ${responseTime}s</div>`
      : "";

  div.innerHTML = `
    <div class="message-avatar">${avatar}</div>
    <div class="message-content"><p>${formatMessage(text)}</p>${timeHtml}</div>
  `;
  container.appendChild(div);
  container.scrollTop = container.scrollHeight;
}

/** Add an action notification to chat. */
function addActionNotification(text) {
  const container = $("chat-messages");
  const notif = document.createElement("div");
  notif.className = "action-notification";
  notif.textContent = `⚡ ${text}`;
  container.appendChild(notif);
  container.scrollTop = container.scrollHeight;
}

/** Show typing indicator, returns element for removal. */
function showTyping() {
  const container = $("chat-messages");
  const div = document.createElement("div");
  div.className = "message ai-message";
  div.innerHTML = `
    <div class="message-avatar">🤖</div>
    <div class="message-content">
      <div class="typing-indicator"><span></span><span></span><span></span></div>
    </div>
  `;
  container.appendChild(div);
  container.scrollTop = container.scrollHeight;
  return div;
}

/** Send a chat message to the API. */
async function sendMessage(withCamera = false) {
  const input = $("chat-input");
  const message = input.value.trim();
  if (!message || state.processing) return;

  addMessage(message, "user");
  input.value = "";
  state.processing = true;

  const image = withCamera && state.camera.active ? captureFrame() : null;
  const typingEl = showTyping();
  const startTime = Date.now();

  try {
    const data = await api(API.chat, {
      method: "POST",
      body: JSON.stringify({ message, image }),
    });
    typingEl.remove();
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);

    if (data.error) {
      addMessage(data.response || data.error, "ai");
    } else {
      addMessage(data.response, "ai", true, elapsed);
      updateMoodUI(data.mood);
      if (data.provider) updateProviderUI(data.provider);
      data.actions?.forEach((a) => {
        if (a.success) {
          addActionNotification(a.message);
          showToast(a.message, "success");
        }
      });
      if (state.voice.active) speak(data.response);
    }
  } catch {
    typingEl.remove();
    addMessage("Maaf, terjadi error koneksi ke server.", "ai");
    showToast("Connection error", "error");
  }
  state.processing = false;
}

/** Send an image file with optional message. */
async function sendImageFile(file) {
  const input = $("chat-input");
  const message = input.value.trim();
  input.value = "";

  addMessage(`[📷 ${file.name}] ${message}`, "user");
  state.processing = true;
  const typingEl = showTyping();

  try {
    const formData = new FormData();
    formData.append("file", file);
    const url = `${API.chatImage}?message=${encodeURIComponent(message)}`;
    const response = await fetch(url, { method: "POST", body: formData });
    const data = await response.json();
    typingEl.remove();

    addMessage(data.response, "ai");
    if (data.mood) updateMoodUI(data.mood);
    if (data.provider) updateProviderUI(data.provider);
    if (state.voice.active) speak(data.response);
  } catch {
    typingEl.remove();
    addMessage("Gagal mengirim gambar.", "ai");
    showToast("Upload error", "error");
  }
  state.processing = false;
}

/** Load conversation history from server. */
async function loadConversationHistory() {
  try {
    const data = await api(`${API.messages}?limit=50`);
    if (data.messages?.length > 0) {
      $("chat-messages").innerHTML = "";
      data.messages.forEach((msg) =>
        addMessage(msg.content, msg.role === "user" ? "user" : "ai", false),
      );
      $("chat-messages").scrollTop = $("chat-messages").scrollHeight;
    }
  } catch {
    /* silent */
  }
}
