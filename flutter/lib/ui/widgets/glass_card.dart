import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.color,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color ??
                (isDark
                    ? Colors.white.withAlpha(15)
                    : Colors.white.withAlpha(200)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(25)
                  : Colors.white.withAlpha(180),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
