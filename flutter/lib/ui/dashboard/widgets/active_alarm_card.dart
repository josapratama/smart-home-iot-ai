import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home/data/model/alarm_event.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class ActiveAlarmCard extends StatefulWidget {
  final List<AlarmEvent> alarms;
  const ActiveAlarmCard({super.key, required this.alarms});

  @override
  State<ActiveAlarmCard> createState() => _ActiveAlarmCardState();
}

class _ActiveAlarmCardState extends State<ActiveAlarmCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkCtrl;
  late Animation<double> _blinkAnim;

  bool get _hasHighSeverity => widget.alarms.any((a) => a.severity == 'high');

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _blinkAnim = Tween<double>(begin: 1.0, end: 0.25)
        .animate(CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut));
    if (_hasHighSeverity) _blinkCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ActiveAlarmCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasHighSeverity && !_blinkCtrl.isAnimating) {
      _blinkCtrl.repeat(reverse: true);
    } else if (!_hasHighSeverity && _blinkCtrl.isAnimating) {
      _blinkCtrl
        ..stop()
        ..value = 1.0;
    }
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highAlarms =
        widget.alarms.where((a) => a.severity == 'high').toList();
    final medAlarms =
        widget.alarms.where((a) => a.severity == 'medium').toList();
    final lowAlarms = widget.alarms.where((a) => a.severity == 'low').toList();

    final LinearGradient gradient;
    final Color shadowColor;
    if (highAlarms.isNotEmpty) {
      gradient = AppGradients.alarmHigh;
      shadowColor = AppColors.primaryDark;
    } else if (medAlarms.isNotEmpty) {
      gradient = AppGradients.alarmMedium;
      shadowColor = AppColors.primaryOnDark;
    } else {
      gradient = AppGradients.alarmLow;
      shadowColor = AppColors.primaryLight;
    }

    final topAlarm = highAlarms.isNotEmpty
        ? highAlarms.first
        : medAlarms.isNotEmpty
            ? medAlarms.first
            : widget.alarms.first;

    return GestureDetector(
      onTap: () => context.go('/alarm'),
      child: AnimatedBuilder(
        animation: _blinkAnim,
        builder: (context, child) => Opacity(
          opacity: _hasHighSeverity ? _blinkAnim.value : 1.0,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.elevated(shadowColor),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -15,
                right: -15,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.overlayLight,
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: 40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.overlayDark,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.base + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _BlinkingIcon(
                          icon: _typeIcon(topAlarm.type),
                          isBlinking: _hasHighSeverity,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.alarms.length} Alarm Aktif',
                                style: AppTextStyles.cardTitle,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topAlarm.message,
                                style: AppTextStyles.cardSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.overlayLight,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Lihat', style: AppTextStyles.badge),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  color: Colors.white, size: 11),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.alarms.length > 1) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(height: 1, color: Colors.white.withAlpha(30)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          if (highAlarms.isNotEmpty)
                            _SeverityChip(
                              count: highAlarms.length,
                              label: 'Tinggi',
                              icon: Icons.local_fire_department_rounded,
                              bg: Colors.white.withAlpha(40),
                            ),
                          if (highAlarms.isNotEmpty && medAlarms.isNotEmpty)
                            const SizedBox(width: AppSpacing.sm),
                          if (medAlarms.isNotEmpty)
                            _SeverityChip(
                              count: medAlarms.length,
                              label: 'Sedang',
                              icon: Icons.warning_amber_rounded,
                              bg: Colors.white.withAlpha(25),
                            ),
                          if (lowAlarms.isNotEmpty) ...[
                            if (highAlarms.isNotEmpty || medAlarms.isNotEmpty)
                              const SizedBox(width: AppSpacing.sm),
                            _SeverityChip(
                              count: lowAlarms.length,
                              label: 'Rendah',
                              icon: Icons.info_outline_rounded,
                              bg: Colors.white.withAlpha(15),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            _timeAgo(topAlarm.triggeredAt),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: AppTextStyles.xs + 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'gas':
        return Icons.air_rounded;
      case 'bin':
        return Icons.delete_outline_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}

class _BlinkingIcon extends StatefulWidget {
  final IconData icon;
  final bool isBlinking;
  const _BlinkingIcon({required this.icon, required this.isBlinking});

  @override
  State<_BlinkingIcon> createState() => _BlinkingIconState();
}

class _BlinkingIconState extends State<_BlinkingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 1.0, end: 1.3)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isBlinking) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_BlinkingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlinking && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isBlinking && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.overlayLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(widget.icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color bg;

  const _SeverityChip({
    required this.count,
    required this.label,
    required this.icon,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: AppSpacing.xs + 1),
          Text('$count $label', style: AppTextStyles.badge),
        ],
      ),
    );
  }
}
