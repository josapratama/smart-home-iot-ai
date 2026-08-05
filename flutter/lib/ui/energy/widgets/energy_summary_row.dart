import 'package:flutter/material.dart';
import 'package:smart_home/data/model/sensor_reading.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class EnergySummaryRow extends StatelessWidget {
  final List<SensorReading> readings;
  const EnergySummaryRow({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    final total = readings.fold<double>(0, (s, r) => s + (r.current ?? 0));
    final avg = readings.isEmpty ? 0.0 : total / readings.length;
    final max = readings.isEmpty
        ? 0.0
        : readings.map((r) => r.current ?? 0).reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total',
            value: '${total.toStringAsFixed(1)}A',
            icon: Icons.bolt_rounded,
            gradient: AppGradients.energyTotal,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryCard(
            label: 'Rata-rata',
            value: '${avg.toStringAsFixed(2)}A',
            icon: Icons.analytics_outlined,
            gradient: AppGradients.energyAvg,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryCard(
            label: 'Tertinggi',
            value: '${max.toStringAsFixed(2)}A',
            icon: Icons.trending_up_rounded,
            gradient: AppGradients.energyMax,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.base),
        boxShadow: AppShadows.cardColored(gradient.colors.first),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.overlayLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: AppTextStyles.metricValue
                  .copyWith(fontSize: AppTextStyles.md - 1)),
          Text(label, style: AppTextStyles.metricLabel),
        ],
      ),
    );
  }
}

// Alias publik agar tidak break import lama
typedef EnergySummaryCard = _SummaryCard;
