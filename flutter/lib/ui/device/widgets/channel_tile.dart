import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home/data/model/device.dart';
import 'package:smart_home/data/repository/auth_repository.dart';
import 'package:smart_home/data/repository/device_repository.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class ChannelTile extends ConsumerWidget {
  final Channel channel;
  final String homeId;
  final String deviceId;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.homeId,
    required this.deviceId,
  });

  Future<void> _toggle(WidgetRef ref, bool newState) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    // sendCommand sekarang langsung update Firestore channel state
    // sehingga UI update instan via stream, lalu kirim MQTT di background
    ref.read(deviceRepositoryProvider).sendCommand(
          homeId: homeId,
          deviceId: deviceId,
          channelPin: channel.pin,
          state: newState,
          sentBy: user.uid,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOn = channel.state;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isOn
            ? AppColors.primaryOnDark.withAlpha(isDark ? 30 : 15)
            : (isDark ? Colors.white.withAlpha(8) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOn
              ? AppColors.primaryOnDark.withAlpha(80)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          _PowerIcon(isOn: isOn, isDark: isDark, name: channel.name),
          const SizedBox(width: 12),
          Expanded(
            child: _ChannelInfo(
              name: channel.name,
              pin: channel.pin,
              isDark: isDark,
            ),
          ),
          _StatusBadge(isOn: isOn),
          const SizedBox(width: 10),
          Switch(
            value: isOn,
            onChanged: (v) => _toggle(ref, v),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────

class _PowerIcon extends StatelessWidget {
  final bool isOn;
  final bool isDark;
  final String name;

  const _PowerIcon({
    required this.isOn,
    required this.isDark,
    required this.name,
  });

  IconData _roomIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('kamar tidur') || n.contains('bedroom')) {
      return Icons.bed_rounded;
    } else if (n.contains('ruang tamu') || n.contains('living')) {
      return Icons.weekend_rounded;
    } else if (n.contains('kamar mandi') ||
        n.contains('wc') ||
        n.contains('toilet') ||
        n.contains('bathroom')) {
      return Icons.bathroom_rounded;
    } else if (n.contains('dapur') || n.contains('kitchen')) {
      return Icons.kitchen_rounded;
    } else if (n.contains('garasi') || n.contains('garage')) {
      return Icons.garage_rounded;
    } else if (n.contains('teras') || n.contains('balkon')) {
      return Icons.deck_rounded;
    } else if (n.contains('lampu') || n.contains('light')) {
      return Icons.lightbulb_rounded;
    } else if (n.contains('ac') || n.contains('kipas') || n.contains('fan')) {
      return Icons.air_rounded;
    }
    return Icons.power_settings_new_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isOn
            ? AppColors.primaryOnDark.withAlpha(30)
            : (isDark ? Colors.white12 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        _roomIcon(name),
        color: isOn ? AppColors.primaryOnDark : Colors.grey,
        size: 20,
      ),
    );
  }
}

class _ChannelInfo extends StatelessWidget {
  final String name;
  final int pin;
  final bool isDark;

  const _ChannelInfo({
    required this.name,
    required this.pin,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.textPrimaryLight,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOn;

  const _StatusBadge({required this.isOn});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isOn ? AppColors.primaryOnDark.withAlpha(25) : Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOn ? 'ON' : 'OFF',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isOn ? AppColors.primaryOnDark : Colors.grey,
        ),
      ),
    );
  }
}
