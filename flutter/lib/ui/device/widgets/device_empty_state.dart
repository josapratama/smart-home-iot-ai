import 'package:flutter/material.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class DeviceEmptyState extends StatelessWidget {
  const DeviceEmptyState({super.key});

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
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryOnDark.withAlpha(30),
                  AppColors.gradientEnd.withAlpha(30),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.devices_rounded,
              size: 48,
              color: AppColors.primaryOnDark,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada perangkat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan perangkat IoT ke sistem Anda',
            textAlign: TextAlign.center,
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
