import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home/data/model/device.dart';
import 'package:smart_home/ui/theme/app_theme.dart';
import 'package:smart_home/ui/device/device_control_screen.dart';
import 'package:smart_home/ui/device/widgets/channel_tile.dart';

class DeviceCard extends ConsumerStatefulWidget {
  final Device device;
  final String homeId;

  const DeviceCard({
    super.key,
    required this.device,
    required this.homeId,
  });

  @override
  ConsumerState<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends ConsumerState<DeviceCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  IconData get _deviceIcon {
    switch (widget.device.type.toLowerCase()) {
      case 'relay':
        return Icons.electrical_services_rounded;
      case 'sensor':
        return Icons.sensors_rounded;
      case 'light':
        return Icons.lightbulb_rounded;
      case 'fan':
        return Icons.air_rounded;
      default:
        return Icons.memory_rounded;
    }
  }

  List<Color> get _gradient => widget.device.isOnline
      ? [AppColors.gradientStart, AppColors.gradientEnd]
      : [Colors.grey.shade400, Colors.grey.shade500];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final channelsAsync = ref.watch(
      channelsProvider((homeId: widget.homeId, deviceId: widget.device.id)),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _DeviceIcon(
                    icon: _deviceIcon,
                    gradient: _gradient,
                    isOnline: widget.device.isOnline,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _DeviceInfo(
                      device: widget.device,
                      isDark: isDark,
                    ),
                  ),
                  _ExpandArrow(expanded: _expanded, isDark: isDark),
                ],
              ),
            ),
          ),

          // ── Channels (expandable) ────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: _ChannelsSection(
              channelsAsync: channelsAsync,
              homeId: widget.homeId,
              deviceId: widget.device.id,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Device Icon ──────────────────────────────────────────────────────────

class _DeviceIcon extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final bool isOnline;

  const _DeviceIcon({
    required this.icon,
    required this.gradient,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: AppColors.primaryOnDark.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}

// ─── Device Info ──────────────────────────────────────────────────────────

class _DeviceInfo extends StatelessWidget {
  final Device device;
  final bool isDark;

  const _DeviceInfo({required this.device, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          device.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Status dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: device.isOnline ? AppColors.primaryOnDark : AppColors.offline,
                shape: BoxShape.circle,
                boxShadow: device.isOnline
                    ? [
                        BoxShadow(
                          color: AppColors.primaryOnDark.withAlpha(120),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              device.isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: device.isOnline ? AppColors.primaryOnDark : AppColors.offline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Expand Arrow ─────────────────────────────────────────────────────────

class _ExpandArrow extends StatelessWidget {
  final bool expanded;
  final bool isDark;

  const _ExpandArrow({required this.expanded, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: expanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white12 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: isDark ? Colors.white54 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

// ─── Channels Section ─────────────────────────────────────────────────────

class _ChannelsSection extends StatelessWidget {
  final AsyncValue<List<Channel>> channelsAsync;
  final String homeId;
  final String deviceId;
  final bool isDark;

  const _ChannelsSection({
    required this.channelsAsync,
    required this.homeId,
    required this.deviceId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: isDark ? Colors.white12 : Colors.grey.shade100,
        ),
        channelsAsync.when(
          data: (channels) => channels.isEmpty
              ? _EmptyChannels(isDark: isDark)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: channels
                        .map((ch) => ChannelTile(
                              channel: ch,
                              homeId: homeId,
                              deviceId: deviceId,
                            ))
                        .toList(),
                  ),
                ),
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              color: AppColors.primaryOnDark,
              strokeWidth: 2,
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyChannels extends StatelessWidget {
  final bool isDark;
  const _EmptyChannels({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            'Tidak ada channel',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
