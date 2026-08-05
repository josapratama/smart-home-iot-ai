/**
 * Camera Module - Webcam capture and control
 */

"use strict";

async function toggleCamera() {
  state.camera.active ? stopCamera() : await startCamera();
}

async function startCamera() {
  try {
    state.camera.stream = await navigator.mediaDevices.getUserMedia({
      video: { width: 640, height: 480, facingMode: "user" },
    });
    $("camera-video").srcObject = state.camera.stream;
    $("camera-container").style.display = "block";
    $("camera-snap-btn").style.display = "flex";
    state.camera.active = true;
    const btn = $("camera-toggle");
    btn.textContent = "📷 ON";
    btn.classList.add("active");
    showToast("Kamera aktif", "success");
  } catch (err) {
    showToast("Gagal mengakses kamera: " + err.message, "error");
  }
}

function stopCamera() {
  state.camera.stream?.getTracks().forEach((t) => t.stop());
  state.camera.stream = null;
  $("camera-video").srcObject = null;
  $("camera-container").style.display = "none";
  $("camera-snap-btn").style.display = "none";
  state.camera.active = false;
  const btn = $("camera-toggle");
  btn.textContent = "📷 OFF";
  btn.classList.remove("active");
}

/** Capture current video frame as base64 JPEG. */
function captureFrame() {
  const canvas = $("camera-canvas");
  const video = $("camera-video");
  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;
  canvas.getContext("2d").drawImage(video, 0, 0);
  return canvas.toDataURL("image/jpeg", 0.8).split(",")[1];
}
