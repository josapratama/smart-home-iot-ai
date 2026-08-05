import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_home/data/model/alarm_event.dart';
import 'package:smart_home/data/repository/alarm_repository.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class AlarmCard extends ConsumerWidget {
  final AlarmEvent alarm;
  final VoidCallback onResolved;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onResolved,
  });

  Color get _severityColor {
    switch (alarm.severity) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.bin; // teal/cyan untuk sampah
      default:
        return AppColors.warning;
    }
  }

  IconData get _typeIcon {
    switch (alarm.type) {
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'gas':
        return Icons.air_rounded;
      case 'bin':
        return Icons.delete_outline_rounded;
      case 'anomaly':
        return Icons.analytics_outlined;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String get _typeLabel {
    switch (alarm.type) {
      case 'fire':
        return 'Kebakaran';
      case 'gas':
        return 'Kebocoran Gas';
      case 'bin':
        return 'Sampah Penuh';
      case 'anomaly':
        return 'Anomali';
      default:
        return 'Peringatan';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'id');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: alarm.isResolved
            ? Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100)
            : Border.all(color: _severityColor.withAlpha(100), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: alarm.isResolved
                ? Colors.black.withAlpha(isDark ? 20 : 8)
                : _severityColor.withAlpha(50),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + badges + resolved check
            Row(
              children: [
                _TypeIcon(
                  icon: _typeIcon,
                  color: _severityColor,
                  faded: alarm.isResolved,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Badge(
                            label: _typeLabel,
                            color: _severityColor,
                          ),
                          const SizedBox(width: 6),
                          _Badge(
                            label: alarm.severity.toUpperCase(),
                            color:
                                isDark ? Colors.white38 : Colors.grey.shade500,
                            bg: isDark ? Colors.white12 : Colors.grey.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(alarm.triggeredAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (alarm.isResolved) _ResolvedBadge(),
              ],
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              alarm.message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                height: 1.4,
              ),
            ),

            // Resolve button
            if (!alarm.isResolved) ...[
              const SizedBox(height: 14),
              _ResolveButton(
                onPressed: () async {
                  await ref
                      .read(alarmRepositoryProvider)
                      .resolveAlarm(alarm.id);
                  onResolved();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool faded;

  const _TypeIcon({
    required this.icon,
    required this.color,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withAlpha(faded ? 15 : 25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: faded ? color.withAlpha(120) : color,
        size: 22,
      ),
    );
  }
}

class _ResolvedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.safe.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.safe,
        size: 16,
      ),
    );
  }
}

class _ResolveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ResolveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
        label: const Text('Tandai Selesai'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.safe,
          foregroundColor: AppColors.onSafe, // putih — kontras di atas hijau
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bg;

  const _Badge({required this.label, required this.color, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
