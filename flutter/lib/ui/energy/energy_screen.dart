import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home/data/repository/sensor_repository.dart';
import 'package:smart_home/data/repository/user_repository.dart';
import 'package:smart_home/data/model/sensor_reading.dart';
import 'package:smart_home/ui/theme/app_theme.dart';
import 'package:smart_home/ui/energy/widgets/energy_summary_row.dart';
import 'package:smart_home/ui/energy/widgets/energy_chart_card.dart';
import 'package:smart_home/ui/energy/widgets/ai_prediction_card.dart';
import 'package:smart_home/ui/energy/widgets/energy_tips_card.dart';
import 'package:smart_home/ui/energy/widgets/energy_section_title.dart';

final energyHistoryProvider = FutureProvider<List<SensorReading>>((ref) {
  final homeId = ref.watch(homeIdProvider);
  if (homeId == null) return Future.value([]);
  return ref.watch(sensorRepositoryProvider).getEnergyHistory(homeId);
});

class EnergyScreen extends ConsumerWidget {
  const EnergyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(energyHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Header gradient — konsisten dengan semua screen
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: AppGradients.header,
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _CircleIconBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.go('/dashboard'),
                      ),
                      const Spacer(),
                      _CircleIconBtn(
                        icon: Icons.refresh_rounded,
                        onTap: () => ref.invalidate(energyHistoryProvider),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Energi & AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Monitoring konsumsi & prediksi cerdas',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgDark : AppColors.bgLight,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: historyAsync.when(
                      data: (readings) => _EnergyContent(readings: readings),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryOnDark,
                        ),
                      ),
                      error: (e, _) => _EnergyErrorState(
                        error: e,
                        onRetry: () => ref.invalidate(energyHistoryProvider),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Energy Content ───────────────────────────────────────────────────────

class _EnergyContent extends StatelessWidget {
  final List<SensorReading> readings;

  const _EnergyContent({required this.readings});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        EnergySummaryRow(readings: readings),
        const SizedBox(height: 24),
        const EnergySectionTitle(
          title: 'Konsumsi 7 Hari Terakhir',
          icon: Icons.show_chart_rounded,
        ),
        const SizedBox(height: 14),
        EnergyChartCard(readings: readings),
        const SizedBox(height: 24),
        const EnergySectionTitle(
          title: 'Prediksi AI',
          icon: Icons.psychology_rounded,
        ),
        const SizedBox(height: 14),
        const AiPredictionCard(),
        const SizedBox(height: 24),
        const EnergySectionTitle(
          title: 'Tips Hemat Energi',
          icon: Icons.tips_and_updates_rounded,
        ),
        const SizedBox(height: 14),
        const EnergyTipsCard(),
      ],
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────

class _EnergyErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _EnergyErrorState({required this.error, required this.onRetry});

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
                  ? 'Firebase sedang membangun index.\nBiasanya selesai dalam 1–5 menit.'
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
                  foregroundColor:
                      _isIndexError ? AppColors.onWarning : AppColors.onDanger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Circle Icon Button ───────────────────────────────────────────────────

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}
