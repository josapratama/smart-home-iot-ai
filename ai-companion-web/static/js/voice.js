/**
 * Voice Module - Text-to-Speech (TTS) & Speech-to-Text (STT)
 */

"use strict";

function toggleVoice() {
  state.voice.active = !state.voice.active;
  const btn = $("voice-toggle");
  btn.textContent = state.voice.active ? "🔊 ON" : "🔇 OFF";
  btn.classList.toggle("active", state.voice.active);
}

/**
 * Speak text using Web Speech API TTS.
 * @param {string} text - Text to speak
 * @param {Function|null} onEnd - Callback when speech finishes
 */
function speak(text, onEnd = null) {
  if (!("speechSynthesis" in window) || !state.voice.active) {
    onEnd?.();
    return;
  }
  const cleanText = cleanTextForSpeech(text);
  if (!cleanText) {
    onEnd?.();
    return;
  }

  speechSynthesis.cancel();
  const utterance = new SpeechSynthesisUtterance(cleanText);
  utterance.lang = "id-ID";
  utterance.rate = 1.0;
  utterance.pitch = 1.1;

  const voices = speechSynthesis.getVoices();
  utterance.voice =
    voices.find((v) => v.lang.startsWith("id")) ||
    voices.find((v) => /female|zira/i.test(v.name)) ||
    voices[0];

  utterance.onend = () => onEnd?.();
  utterance.onerror = () => onEnd?.();
  speechSynthesis.speak(utterance);
}

/** Toggle microphone for manual voice input. */
function toggleMic() {
  const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!SR) {
    showToast("Browser tidak mendukung Speech Recognition", "error");
    return;
  }
  state.voice.recording ? stopRecording() : startRecording(SR);
}

function startRecording(SR) {
  const recognition = new SR();
  recognition.lang = "id-ID";
  recognition.continuous = false;
  recognition.interimResults = false;

  recognition.onstart = () => {
    state.voice.recording = true;
    const btn = $("mic-btn");
    btn.classList.add("recording");
    btn.textContent = "⏹️";
    showToast("🎤 Mendengarkan...", "success");
  };
  recognition.onresult = (e) => {
    $("chat-input").value = e.results[0][0].transcript;
    stopRecording();
    sendMessage();
  };
  recognition.onerror = (e) => {
    if (e.error !== "no-speech") showToast(`Voice: ${e.error}`, "error");
    stopRecording();
  };
  recognition.onend = () => stopRecording();

  state.voice.recognition = recognition;
  recognition.start();
}

function stopRecording() {
  state.voice.recognition?.stop();
  state.voice.recognition = null;
  state.voice.recording = false;
  const btn = $("mic-btn");
  btn.classList.remove("recording");
  btn.textContent = "🎤";
}
