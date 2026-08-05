import 'package:flutter/material.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class EnergySectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const EnergySectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Di dark mode, gunakan warna terang agar ikon & teks terbaca
    final iconColor = isDark ? AppColors.primaryOnDark : AppColors.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(isDark ? 35 : 25),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.sectionTitle.copyWith(
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
