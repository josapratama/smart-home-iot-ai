import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home/data/model/energy_prediction.dart';
import 'package:smart_home/data/repository/prediction_repository.dart';
import 'package:smart_home/data/repository/user_repository.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

final _latestPredictionProvider = StreamProvider<EnergyPrediction?>((ref) {
  final homeId = ref.watch(homeIdProvider);
  if (homeId == null) return const Stream.empty();
  return ref.watch(predictionRepositoryProvider).watchLatestPrediction(homeId);
});

final _latestAnomalyProvider = StreamProvider<AnomalyResult?>((ref) {
  final homeId = ref.watch(homeIdProvider);
  if (homeId == null) return const Stream.empty();
  return ref.watch(predictionRepositoryProvider).watchLatestAnomaly(homeId);
});

class AiPredictionCard extends ConsumerWidget {
  const AiPredictionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predAsync = ref.watch(_latestPredictionProvider);
    final anomalyAsync = ref.watch(_latestAnomalyProvider);

    final pred = predAsync.valueOrNull;
    final anomaly = anomalyAsync.valueOrNull;

    final predictedStr =
        pred != null ? '${pred.predictedKwh.toStringAsFixed(2)} A' : '--';
    final actualStr =
        pred != null ? '${pred.actualKwh.toStringAsFixed(2)} A' : '--';
    final mapeStr = pred != null ? '${pred.mape.toStringAsFixed(1)}%' : '--%';

    final anomalyStatus = anomaly == null
        ? 'Menunggu data dari model AI'
        : anomaly.isAnomaly
            ? '⚠️ Anomali terdeteksi (skor: ${anomaly.score.toStringAsFixed(2)})'
            : '✅ Normal (skor: ${anomaly.score.toStringAsFixed(2)})';

    final anomalyColor = anomaly == null
        ? Colors.white70
        : anomaly.isAnomaly
            ? AppColors.danger
            : AppColors.safe;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.pzem,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.elevated(AppColors.primaryOnDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.overlayLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text('Prediksi Energi (AI)',
                    style: AppTextStyles.cardTitle),
                const Spacer(),
                predAsync.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white70),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.overlayLight,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          pred != null ? 'LIVE' : 'IDLE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppTextStyles.xs,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Metrics
            Row(
              children: [
                Expanded(
                  child: _Metric(
                      label: 'Prediksi',
                      value: predictedStr,
                      icon: Icons.trending_up_rounded),
                ),
                Container(
                    width: 1, height: 50, color: Colors.white.withAlpha(40)),
                Expanded(
                  child: _Metric(
                      label: 'Aktual',
                      value: actualStr,
                      icon: Icons.bolt_rounded),
                ),
                Container(
                    width: 1, height: 50, color: Colors.white.withAlpha(40)),
                Expanded(
                  child: _Metric(
                      label: 'MAPE',
                      value: mapeStr,
                      icon: Icons.percent_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),

            // Anomaly status
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    anomaly == null
                        ? Icons.info_outline_rounded
                        : anomaly.isAnomaly
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                    color: anomalyColor,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Status Anomali: $anomalyStatus',
                      style: AppTextStyles.bodySm.copyWith(color: anomalyColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Metric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        Text(value,
            style: AppTextStyles.metricValue
                .copyWith(fontSize: AppTextStyles.md - 1)),
        Text(label, style: AppTextStyles.metricLabel),
      ],
    );
  }
}
