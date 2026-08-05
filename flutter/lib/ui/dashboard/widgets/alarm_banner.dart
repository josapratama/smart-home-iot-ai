import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home/data/model/alarm_event.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class AlarmBanner extends StatelessWidget {
  final List<AlarmEvent> alarms;

  const AlarmBanner({super.key, required this.alarms});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.danger.withAlpha(220),
            AppColors.danger.withAlpha(180),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alarms.length} Alarm Aktif!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  alarms.first.message,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => GoRouter.of(context).go('/alarm'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withAlpha(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'Lihat',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
