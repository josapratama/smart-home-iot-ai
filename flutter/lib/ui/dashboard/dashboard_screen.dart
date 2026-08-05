import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home/data/repository/auth_repository.dart';
import 'package:smart_home/data/repository/sensor_repository.dart';
import 'package:smart_home/data/repository/alarm_repository.dart';
import 'package:smart_home/data/repository/user_repository.dart';
import 'package:smart_home/data/model/sensor_reading.dart';
import 'package:smart_home/data/model/alarm_event.dart';
import 'package:smart_home/ui/theme/app_theme.dart';
import 'package:smart_home/ui/dashboard/widgets/dashboard_app_bar.dart';
import 'package:smart_home/ui/dashboard/widgets/active_alarm_card.dart';
import 'package:smart_home/ui/dashboard/widgets/sensor_grid.dart';
import 'package:smart_home/ui/dashboard/widgets/home_summary_card.dart';
import 'package:smart_home/ui/dashboard/widgets/system_status_card.dart';
import 'package:smart_home/ui/dashboard/widgets/profile_sheet.dart';

final latestReadingsProvider = StreamProvider<List<SensorReading>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return const Stream.empty();
  final profileAsync = ref.watch(userProfileProvider);
  if (!profileAsync.hasValue) return const Stream.empty();
  final homeId = profileAsync.value?.homeId;
  if (homeId == null) return const Stream.empty();
  return ref.watch(sensorRepositoryProvider).watchLatestReadings(homeId);
});

final activeAlarmsProvider = StreamProvider<List<AlarmEvent>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return const Stream.empty();
  final profileAsync = ref.watch(userProfileProvider);
  if (!profileAsync.hasValue) return const Stream.empty();
  final homeId = profileAsync.value?.homeId;
  if (homeId == null) return const Stream.empty();
  return ref.watch(alarmRepositoryProvider).watchActiveAlarms(homeId);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(latestReadingsProvider);
    final alarmsAsync = ref.watch(activeAlarmsProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    // profileAsync tidak dipakai untuk block UI — hanya untuk data
    ref.watch(userProfileProvider);

    final firstName = (user?.displayName ?? 'Pengguna').split(' ').first;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(latestReadingsProvider),
        color: AppColors.primaryOnDark,
        child: CustomScrollView(
          slivers: [
            DashboardAppBar(
              firstName: firstName,
              photoUrl: user?.photoURL,
              hasActiveAlarm: alarmsAsync.valueOrNull?.isNotEmpty == true,
              onAlarmTap: () => context.go('/alarm'),
              onAvatarTap: () => showProfileSheet(
                context,
                ref,
                name: user?.displayName,
                email: user?.email,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner setup rumah jika homeId belum ada
                    Consumer(
                      builder: (context, ref, _) {
                        final profile = ref.watch(userProfileProvider);
                        if (!profile.hasValue) return const SizedBox.shrink();
                        final homeId = profile.value?.homeId;
                        if (homeId != null && homeId.isNotEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _SetupHomeBanner();
                      },
                    ),

                    // Active alarm card
                    alarmsAsync.when(
                      data: (alarms) => alarms.isEmpty
                          ? const SizedBox.shrink()
                          : ActiveAlarmCard(alarms: alarms),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Sensor section
                    const _SectionHeader(
                      title: 'Sensor Real-time',
                      icon: Icons.sensors_rounded,
                    ),
                    const SizedBox(height: 14),
                    readingsAsync.when(
                      data: (readings) => readings.isEmpty
                          ? const SensorEmptyState()
                          : SensorGrid(readings: readings),
                      loading: () => const SensorGridSkeleton(),
                      error: (e, _) => _ErrorCard(message: 'Error: $e'),
                    ),

                    const SizedBox(height: 28),

                    // Home summary
                    const _SectionHeader(
                      title: 'Ringkasan Rumah',
                      icon: Icons.home_rounded,
                    ),
                    const SizedBox(height: 14),
                    HomeSummaryCard(
                      readingsAsync: readingsAsync,
                      alarmsAsync: alarmsAsync,
                    ),

                    const SizedBox(height: 28),

                    // System status
                    const _SectionHeader(
                      title: 'Status Sistem',
                      icon: Icons.monitor_heart_outlined,
                    ),
                    const SizedBox(height: 14),
                    const SystemStatusCard(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header (local, simple enough to stay here) ───────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.primaryOnDark : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(isDark ? 35 : 25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
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
        ],
      ),
    );
  }
}

// ─── Error Card ───────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Setup Home Banner ────────────────────────────────────────────────────

class _SetupHomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withAlpha(220),
            AppColors.warning.withAlpha(180),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.home_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rumah belum diatur',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Buat atau gabung rumah untuk mulai',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => GoRouter.of(context).go('/setup-home'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withAlpha(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'Atur',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
