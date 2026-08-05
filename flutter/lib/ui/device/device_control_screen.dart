import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home/data/repository/auth_repository.dart';
import 'package:smart_home/data/repository/device_repository.dart';
import 'package:smart_home/data/repository/user_repository.dart';
import 'package:smart_home/data/model/device.dart';
import 'package:smart_home/ui/theme/app_theme.dart';
import 'package:smart_home/ui/device/widgets/device_card.dart';
import 'package:smart_home/ui/device/widgets/device_empty_state.dart';
import 'package:smart_home/ui/device/widgets/device_error_state.dart';

// Provider di level file — stabil, tidak re-create saat rebuild
final devicesProvider = StreamProvider.family<List<Device>, String>(
  (ref, homeId) {
    if (homeId.isEmpty) return const Stream.empty();
    // Tunggu auth state siap
    final authState = ref.watch(authStateProvider);
    if (authState.valueOrNull == null) return const Stream.empty();
    return ref.watch(deviceRepositoryProvider).watchDevices(homeId);
  },
);

final channelsProvider =
    StreamProvider.family<List<Channel>, ({String homeId, String deviceId})>(
  (ref, args) {
    if (args.homeId.isEmpty || args.deviceId.isEmpty) {
      return const Stream.empty();
    }
    return ref
        .watch(deviceRepositoryProvider)
        .watchChannels(args.homeId, args.deviceId);
  },
);

class DeviceControlScreen extends ConsumerWidget {
  final String deviceId;
  const DeviceControlScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final homeId = deviceId.isNotEmpty
        ? deviceId
        : (profileAsync.valueOrNull?.homeId ?? '');

    return Scaffold(
      body: Stack(
        children: [
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _CircleIconBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.go('/dashboard'),
                      ),
                      const Spacer(),
                      if (homeId.isNotEmpty)
                        _CircleIconBtn(
                          icon: Icons.refresh_rounded,
                          onTap: () => ref.invalidate(devicesProvider(homeId)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kontrol Perangkat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kelola semua perangkat IoT Anda',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgDark : AppColors.bgLight,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: _DeviceContent(homeId: homeId),
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

// ─── Device Content ───────────────────────────────────────────────────────

class _DeviceContent extends ConsumerWidget {
  final String homeId;
  const _DeviceContent({required this.homeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // homeId kosong → profile masih loading atau belum setup
    if (homeId.isEmpty) {
      // Cek apakah profile masih loading
      final profileAsync = ref.watch(userProfileProvider);
      if (profileAsync.isLoading || !profileAsync.hasValue) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOnDark),
        );
      }
      return const _NoHomeState();
    }

    // homeId valid → query Firestore
    final devicesAsync = ref.watch(devicesProvider(homeId));

    return devicesAsync.when(
      data: (devices) => devices.isEmpty
          ? const DeviceEmptyState()
          : _DeviceList(devices: devices, homeId: homeId),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOnDark),
      ),
      error: (e, _) => DeviceErrorState(message: '$e'),
    );
  }
}

// ─── No Home State ────────────────────────────────────────────────────────

class _NoHomeState extends StatelessWidget {
  const _NoHomeState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: AppColors.warning.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_outlined,
                size: 40,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Rumah Belum Diatur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Atur rumah Anda terlebih dahulu\ndi halaman Beranda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/setup-home'),
              icon: const Icon(Icons.add_home_rounded, size: 18),
              label: const Text('Atur Rumah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOnDark,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Device List ──────────────────────────────────────────────────────────

class _DeviceList extends StatelessWidget {
  final List<Device> devices;
  final String homeId;

  const _DeviceList({required this.devices, required this.homeId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      itemCount: devices.length,
      itemBuilder: (_, i) => DeviceCard(
        device: devices[i],
        homeId: homeId,
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
