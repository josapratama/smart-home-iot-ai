/**
 * Centralized Application State
 */

"use strict";

const state = {
  camera: { active: false, stream: null },
  voice: { active: true, recording: false, recognition: null },
  handsFree: { active: false, listening: false },
  processing: false,
  currentProvider: "gemini",
  pollingIds: { sensors: null, notifications: null },
};
