import 'package:flutter/material.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class EnergyTipsCard extends StatelessWidget {
  const EnergyTipsCard({super.key});

  // Semua warna pakai AppColors — tidak ada hardcoded
  static const _tips = [
    _Tip(
      icon: Icons.lightbulb_outline_rounded,
      text: 'Matikan lampu saat tidak digunakan',
      color: AppColors.warning,
    ),
    _Tip(
      icon: Icons.ac_unit_rounded,
      text: 'Set AC di suhu 24–26°C untuk efisiensi optimal',
      color: AppColors.info,
    ),
    _Tip(
      icon: Icons.schedule_rounded,
      text: 'Gunakan timer untuk perangkat berdaya tinggi',
      color: AppColors.primaryOnDark,
    ),
    _Tip(
      icon: Icons.power_off_rounded,
      text: 'Cabut charger saat tidak digunakan',
      color: AppColors.safe,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        children:
            _tips.map((tip) => _TipRow(tip: tip, isDark: isDark)).toList(),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final _Tip tip;
  final bool isDark;
  const _TipRow({required this.tip, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: tip.color.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(tip.icon, color: tip.color, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              tip.text,
              style: AppTextStyles.bodySm.copyWith(
                height: 1.4,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip {
  final IconData icon;
  final String text;
  final Color color;
  const _Tip({required this.icon, required this.text, required this.color});
}
