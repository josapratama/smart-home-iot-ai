import 'package:flutter/material.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class DeviceErrorState extends StatelessWidget {
  final String message;

  const DeviceErrorState({super.key, required this.message});

  bool get _isIndexError => message.contains('failed-precondition');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _isIndexError ? AppColors.warning : AppColors.danger;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isIndexError
                    ? Icons.hourglass_top_rounded
                    : Icons.error_outline_rounded,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isIndexError ? 'Index Sedang Disiapkan' : 'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isIndexError
                  ? 'Firebase sedang membangun index.\nBiasanya selesai dalam 1–5 menit.'
                  : message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
