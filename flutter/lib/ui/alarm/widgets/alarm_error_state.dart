import 'package:flutter/material.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class AlarmErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const AlarmErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  bool get _isIndexError => error.toString().contains('failed-precondition');

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
                  ? 'Firebase sedang membangun index untuk query ini.\nBiasanya selesai dalam 1–5 menit.\nSilakan coba lagi sebentar.'
                  : error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  // Teks kontras: putih untuk merah, gelap untuk kuning
                  foregroundColor:
                      _isIndexError ? AppColors.onWarning : AppColors.onDanger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
