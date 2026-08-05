/**
 * Automation Rules Module - CRUD for sensor-based automation rules
 */

"use strict";

async function loadAutomationRules() {
  try {
    const rules = await api(API.automationRules);
    renderRules(rules);
  } catch {
    /* silent */
  }
}

function renderRules(rules) {
  const container = $("rules-list");
  if (!rules?.length) {
    container.innerHTML = '<p class="empty-state">Belum ada rule.</p>';
    return;
  }
  container.innerHTML = rules
    .map(
      (r) => `
    <div class="rule-card ${r.enabled ? "" : "disabled"}">
      <div class="rule-info">
        <div class="rule-name">${r.name}</div>
        <div class="rule-condition">
          ${r.sensor} ${r.operator} ${r.threshold}
          ${r.actions.length ? `→ ${r.actions.length} aksi` : "(notif saja)"}
          • CD: ${r.cooldown_minutes}m
          ${r.trigger_count ? `• ×${r.trigger_count}` : ""}
        </div>
      </div>
      <div class="rule-actions-btns">
        <button class="rule-toggle-btn" onclick="toggleRule('${r.id}')">${r.enabled ? "⏸️" : "▶️"}</button>
        <button class="rule-delete-btn" onclick="deleteRule('${r.id}')">🗑️</button>
      </div>
    </div>
  `,
    )
    .join("");
}

async function addAutomationRule() {
  const name = $("rule-name").value.trim();
  const threshold = parseFloat($("rule-threshold").value);
  if (!name || isNaN(threshold)) {
    showToast("Isi nama dan threshold", "error");
    return;
  }

  const actionTarget = $("rule-action-target").value;
  const actionState = $("rule-action-state").value;
  const allTargets = ["kamar tidur", "ruang tamu", "kamar mandi", "dapur"];

  const actions =
    actionTarget === "all"
      ? allTargets.map((t) => ({ target: t, state: actionState }))
      : actionTarget
        ? [{ target: actionTarget, state: actionState }]
        : [];

  try {
    const data = await api(API.automationRules, {
      method: "POST",
      body: JSON.stringify({
        name,
        sensor: $("rule-sensor").value,
        operator: $("rule-operator").value,
        threshold,
        actions,
        cooldown_minutes: parseInt($("rule-cooldown").value) || 5,
        notify: true,
      }),
    });
    if (data.success) {
      showToast("Rule ditambahkan ✓", "success");
      $("rule-name").value = "";
      $("rule-threshold").value = "";
      loadAutomationRules();
    }
  } catch {
    showToast("Gagal menambah rule", "error");
  }
}

async function toggleRule(id) {
  try {
    await api(`${API.automationRules}/${id}/toggle`, { method: "POST" });
    loadAutomationRules();
  } catch {
    showToast("Gagal toggle rule", "error");
  }
}

async function deleteRule(id) {
  try {
    await api(`${API.automationRules}/${id}`, { method: "DELETE" });
    showToast("Rule dihapus", "success");
    loadAutomationRules();
  } catch {
    showToast("Gagal hapus rule", "error");
  }
}

// ── Notifications ────────────────────────────────────────────────────────────

async function loadNotifications() {
  try {
    const list = await api(API.automationNotifications);
    renderNotifications(list);
  } catch {
    /* silent */
  }
}

function renderNotifications(list) {
  const container = $("notifications-list");
  if (!list?.length) {
    container.innerHTML = '<p class="empty-state">Tidak ada notifikasi</p>';
    return;
  }
  container.innerHTML = [...list]
    .reverse()
    .map((n) => {
      const icon = n.type === "danger" ? "🚨" : "⚠️";
      const time = n.timestamp
        ? new Date(n.timestamp).toLocaleTimeString("id-ID")
        : "";
      return `
      <div class="notif-item ${n.type}">
        <span class="notif-icon">${icon}</span>
        <div class="notif-text">
          <strong>${n.rule_name}</strong><br>
          ${n.sensor}: ${n.value} (threshold: ${n.threshold})
          ${n.actions_executed > 0 ? `• ${n.actions_executed} aksi` : ""}
        </div>
        <span class="notif-time">${time}</span>
      </div>`;
    })
    .join("");
  if (list.some((n) => n.type === "danger")) playAlertSound();
}

async function clearNotifications() {
  try {
    await api(API.automationNotifications, { method: "DELETE" });
    $("notifications-list").innerHTML =
      '<p class="empty-state">Tidak ada notifikasi</p>';
    showToast("Notifikasi dihapus", "success");
  } catch {
    showToast("Gagal menghapus", "error");
  }
}
