import 'package:flutter/material.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class AlarmSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const AlarmSectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
