/**
 * Hands-Free Mode - Continuous voice interaction with camera
 * Flow: Listen → Send (with photo) → AI responds via TTS → Resume listening
 */

"use strict";

function toggleHandsFree() {
  state.handsFree.active ? stopHandsFree() : startHandsFree();
}

async function startHandsFree() {
  // Ensure camera is on
  if (!state.camera.active) {
    await startCamera();
    if (!state.camera.active) {
      showToast("Kamera harus aktif", "error");
      return;
    }
  }

  // Ensure voice output is on
  state.voice.active = true;
  $("voice-toggle").textContent = "🔊 ON";
  $("voice-toggle").classList.add("active");

  state.handsFree.active = true;
  const btn = $("handsfree-btn");
  btn.classList.add("active");
  btn.textContent = "🙌 ON";

  showToast("🙌 Hands-free aktif! Bicara langsung.", "success");
  addActionNotification(
    "Hands-free mode aktif — bicara langsung, AI akan menjawab",
  );
  startHandsFreeListen();
}

function stopHandsFree() {
  state.handsFree.active = false;
  state.handsFree.listening = false;
  const btn = $("handsfree-btn");
  btn.classList.remove("active");
  btn.textContent = "🙌 OFF";
  showToast("Hands-free dimatikan", "success");
}

/** Start continuous speech recognition for hands-free mode. */
function startHandsFreeListen() {
  if (state.handsFree.listening || state.processing || !state.handsFree.active)
    return;

  const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!SR) {
    showToast("Speech Recognition tidak tersedia", "error");
    return;
  }

  state.handsFree.listening = true;
  const recognition = new SR();
  recognition.lang = "id-ID";
  recognition.continuous = true;
  recognition.interimResults = false;

  recognition.onstart = () => {
    $("handsfree-btn").textContent = "🎤 Listening...";
  };

  recognition.onresult = async (event) => {
    const transcript = event.results[event.results.length - 1][0].transcript;
    if (transcript.trim().length < 2) return;

    try {
      recognition.stop();
    } catch {}
    state.handsFree.listening = false;

    addMessage(transcript, "user");
    state.processing = true;
    $("handsfree-btn").textContent = "🤔 Thinking...";

    const image = state.camera.active ? captureFrame() : null;
    const typingEl = showTyping();

    try {
      const data = await api(API.chat, {
        method: "POST",
        body: JSON.stringify({ message: transcript, image }),
      });
      typingEl.remove();

      if (data.response) {
        addMessage(data.response, "ai");
        if (data.mood) updateMoodUI(data.mood);
        if (data.provider) updateProviderUI(data.provider);
        data.actions?.forEach((a) => {
          if (a.success) addActionNotification(a.message);
        });

        // Speak response, then resume listening
        speak(data.response, () => resumeHandsFree());
      } else {
        resumeHandsFree();
      }
    } catch {
      typingEl.remove();
      addMessage("Maaf, terjadi error.", "ai");
      resumeHandsFree();
    }
    state.processing = false;
    if (state.handsFree.active) $("handsfree-btn").textContent = "🙌 ON";
  };

  recognition.onerror = (event) => {
    if (event.error !== "no-speech" && event.error !== "aborted") {
      showToast(`Voice: ${event.error}`, "error");
    }
  };

  recognition.onend = () => {
    state.handsFree.listening = false;
    if (state.handsFree.active && !state.processing) {
      $("handsfree-btn").textContent = "🙌 ON";
      setTimeout(() => resumeHandsFree(), HANDSFREE_RESTART_DELAY);
    }
  };

  recognition.start();
}

/** Resume hands-free listening after a delay. */
function resumeHandsFree() {
  setTimeout(() => {
    if (
      state.handsFree.active &&
      !state.processing &&
      !state.handsFree.listening
    ) {
      startHandsFreeListen();
    }
  }, HANDSFREE_RESTART_DELAY);
}
