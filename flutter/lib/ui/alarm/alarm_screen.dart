import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home/data/repository/alarm_repository.dart';
import 'package:smart_home/data/repository/user_repository.dart';
import 'package:smart_home/data/model/alarm_event.dart';
import 'package:smart_home/ui/theme/app_theme.dart';
import 'package:smart_home/ui/alarm/widgets/alarm_card.dart';
import 'package:smart_home/ui/alarm/widgets/alarm_error_state.dart';
import 'package:smart_home/ui/alarm/widgets/alarm_empty_state.dart';
import 'package:smart_home/ui/alarm/widgets/alarm_section_header.dart';

final alarmHistoryProvider = FutureProvider<List<AlarmEvent>>((ref) {
  final homeId = ref.watch(homeIdProvider);
  if (homeId == null) return Future.value([]);
  return ref.watch(alarmRepositoryProvider).getAlarmHistory(homeId);
});

class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Header gradient — konsisten dengan semua screen
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
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _CircleIconBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.go('/dashboard'),
                      ),
                      const Spacer(),
                      _CircleIconBtn(
                        icon: Icons.refresh_rounded,
                        onTap: () => ref.invalidate(alarmHistoryProvider),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title + subtitle dinamis
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Riwayat Alarm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      alarmsAsync.when(
                        data: (alarms) {
                          final active =
                              alarms.where((a) => !a.isResolved).length;
                          return Text(
                            active > 0
                                ? '$active alarm aktif perlu perhatian'
                                : 'Semua alarm sudah ditangani',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        },
                        loading: () => const Text(
                          'Memuat...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Content area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgDark : AppColors.bgLight,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: alarmsAsync.when(
                      data: (alarms) => _AlarmList(
                        alarms: alarms,
                        onRefresh: () => ref.invalidate(alarmHistoryProvider),
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.danger,
                        ),
                      ),
                      error: (e, _) => AlarmErrorState(
                        error: e,
                        onRetry: () => ref.invalidate(alarmHistoryProvider),
                      ),
                    ),
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

// ─── Alarm List ───────────────────────────────────────────────────────────

class _AlarmList extends ConsumerWidget {
  final List<AlarmEvent> alarms;
  final VoidCallback onRefresh;

  const _AlarmList({required this.alarms, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (alarms.isEmpty) return const AlarmEmptyState();

    final active = alarms.where((a) => !a.isResolved).toList();
    final resolved = alarms.where((a) => a.isResolved).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        if (active.isNotEmpty) ...[
          AlarmSectionHeader(
            title: 'Aktif',
            count: active.length,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          ...active.map((a) => AlarmCard(alarm: a, onResolved: onRefresh)),
          const SizedBox(height: 24),
        ],
        if (resolved.isNotEmpty) ...[
          AlarmSectionHeader(
            title: 'Selesai',
            count: resolved.length,
            color: AppColors.safe,
          ),
          const SizedBox(height: 12),
          ...resolved.map((a) => AlarmCard(alarm: a, onResolved: onRefresh)),
        ],
      ],
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
