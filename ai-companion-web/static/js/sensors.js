/**
 * Sensor Dashboard Module - Real-time sensor data display
 */

"use strict";

async function loadSensorData() {
  try {
    const data = await api(API.sensors);
    updateSensorUI(data);
  } catch {
    /* silent */
  }
}

function updateSensorUI(data) {
  // Energy
  if (data.energy) {
    $("sensor-power-val").textContent =
      `${(data.energy.power || 0).toFixed(1)} W`;
    $("sensor-voltage-val").textContent =
      `${(data.energy.voltage || 0).toFixed(0)}V / ${(data.energy.current || 0).toFixed(2)}A`;
  }

  // Gas
  if (data.gas) {
    const ppm = data.gas.gasPpm || 0;
    $("sensor-gas-val").textContent = `${ppm} PPM`;
    const card = $("sensor-gas");
    card.classList.toggle("alert", !!data.gas.gasAlert);
    card.classList.toggle("warning", !data.gas.gasAlert && ppm > 300);
    $("sensor-gas-status").textContent = data.gas.gasAlert
      ? "⚠️ ALERT!"
      : ppm > 300
        ? "Tinggi"
        : "Normal";
  }

  // Fire
  if (data.fire) {
    const detected = !!data.fire.flameDetected;
    $("sensor-fire-val").textContent = detected ? "🚨 TERDETEKSI!" : "Aman ✓";
    $("sensor-fire").classList.toggle("alert", detected);
    if (detected) playAlertSound();
  }

  // Alarms
  if (data.alarms) {
    const count = data.alarms.length;
    $("sensor-alarm-val").textContent = count;
    $("sensor-alarm").classList.toggle("warning", count > 0);
    $("sensor-alarm-status").textContent =
      count > 0
        ? data.alarms[0].message || `${count} alarm aktif`
        : "Tidak ada alarm";
  }

  // Energy today
  if (data.energy_today) {
    $("energy-avg").textContent = `${data.energy_today.avg_power || 0} W`;
    $("energy-max").textContent = `${data.energy_today.max_power || 0} W`;
    $("energy-count").textContent = data.energy_today.readings_count || 0;
  }
}
