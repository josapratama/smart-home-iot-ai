import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home/data/model/sensor_reading.dart';
import 'package:smart_home/data/model/alarm_event.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

/// Menggantikan "Aksi Cepat" — menampilkan ringkasan kondisi rumah
/// yang lebih informatif daripada tombol navigasi duplikat.
class HomeSummaryCard extends StatelessWidget {
  final AsyncValue<List<SensorReading>> readingsAsync;
  final AsyncValue<List<AlarmEvent>> alarmsAsync;

  const HomeSummaryCard({
    super.key,
    required this.readingsAsync,
    required this.alarmsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final readings = readingsAsync.valueOrNull ?? [];
    final alarms = alarmsAsync.valueOrNull ?? [];

    final energy = readings.where((r) => r.type == 'energy').firstOrNull;
    final gas = readings.where((r) => r.type == 'gas').firstOrNull;
    final fire = readings.where((r) => r.type == 'fire').firstOrNull;

    final activeAlarms = alarms.where((a) => !a.isResolved).length;

    // Hitung skor keamanan sederhana
    int safeCount = 0;
    if ((gas?.gasPpm ?? 0) <= 400) safeCount++;
    if (fire?.flameDetected != true) safeCount++;
    if (activeAlarms == 0) safeCount++;
    final safeScore = (safeCount / 3 * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Safety score row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skor Keamanan',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$safeScore',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: _scoreColor(safeScore),
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 2),
                          child: Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: safeScore / 100,
                        minHeight: 6,
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _scoreColor(safeScore),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _scoreColor(safeScore).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _scoreIcon(safeScore),
                  color: _scoreColor(safeScore),
                  size: 32,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade100,
          ),
          const SizedBox(height: 16),

          // Stats row — tampilkan semua sensor yang ada
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Daya',
                  value: energy != null
                      ? '${energy.power?.toStringAsFixed(0)}W'
                      : '--',
                  icon: Icons.power_rounded,
                  color: AppColors.energy,
                ),
              ),
              _Divider(),
              Expanded(
                child: _StatItem(
                  label: 'Gas',
                  value: gas != null ? '${gas.gasPpm} ppm' : '--',
                  icon: Icons.air_rounded,
                  color: (gas?.gasPpm ?? 0) > 400
                      ? AppColors.danger
                      : AppColors.safe,
                ),
              ),
              _Divider(),
              Expanded(
                child: _StatItem(
                  label: 'Api',
                  value: fire != null
                      ? (fire.flameDetected == true ? 'Ada!' : 'Aman')
                      : '--',
                  icon: Icons.local_fire_department_rounded,
                  color: fire?.flameDetected == true
                      ? AppColors.danger
                      : AppColors.safe,
                ),
              ),
              _Divider(),
              Expanded(
                child: _StatItem(
                  label: 'Alarm',
                  value: '$activeAlarms',
                  icon: Icons.notifications_rounded,
                  color: activeAlarms > 0 ? AppColors.danger : AppColors.safe,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.safe;
    if (score >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  IconData _scoreIcon(int score) {
    if (score >= 80) return Icons.shield_rounded;
    if (score >= 50) return Icons.shield_outlined;
    return Icons.warning_amber_rounded;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 50,
      color: isDark ? Colors.white12 : Colors.grey.shade100,
    );
  }
}
