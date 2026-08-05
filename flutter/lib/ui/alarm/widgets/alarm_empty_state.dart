import 'package:flutter/material.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class AlarmEmptyState extends StatelessWidget {
  const AlarmEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.safe.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: AppColors.safe,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Semua Aman! 🎉',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada riwayat alarm',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
