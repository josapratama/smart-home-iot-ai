import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_home/data/repository/user_repository.dart';
import 'package:smart_home/data/repository/prediction_repository.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

/// Cek koneksi Firestore — online jika snapshot datang dari server (bukan cache)
final _firestoreStatusProvider = StreamProvider<bool>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      .map<bool>((snap) => !snap.metadata.isFromCache)
      .distinct(); // hanya emit kalau status berubah
});

/// Status homeId — apakah sudah terhubung ke rumah
final _homeStatusProvider = Provider<bool>((ref) {
  return ref.watch(homeIdProvider) != null;
});

/// Cek apakah ada data prediksi AI terbaru (dalam 24 jam terakhir)
final _aiStatusProvider = StreamProvider<_AiStatus>((ref) {
  final homeId = ref.watch(homeIdProvider);
  if (homeId == null) {
    return Stream.value(_AiStatus.noHome);
  }
  return ref
      .watch(predictionRepositoryProvider)
      .watchLatestPrediction(homeId)
      .map((pred) {
    if (pred == null) return _AiStatus.noData;
    final age = DateTime.now().difference(pred.createdAt);
    if (age.inHours > 24) return _AiStatus.stale;
    return _AiStatus.active;
  });
});

enum _AiStatus { noHome, noData, stale, active }

class SystemStatusCard extends ConsumerWidget {
  const SystemStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestoreAsync = ref.watch(_firestoreStatusProvider);
    final homeLinked = ref.watch(_homeStatusProvider);
    final aiAsync = ref.watch(_aiStatusProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Firebase status — real check
          firestoreAsync.when(
            data: (connected) => _StatusRow(
              label: 'Firebase',
              status: connected ? 'Terhubung' : 'Offline',
              color: connected ? AppColors.safe : AppColors.danger,
              icon: connected
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
            ),
            loading: () => const _StatusRow(
              label: 'Firebase',
              status: 'Memeriksa...',
              color: AppColors.warning,
              icon: Icons.cloud_sync_rounded,
            ),
            error: (_, __) => const _StatusRow(
              label: 'Firebase',
              status: 'Error',
              color: AppColors.danger,
              icon: Icons.cloud_off_rounded,
            ),
          ),

          const Divider(height: 20),

          // Home linked status
          _StatusRow(
            label: 'Rumah',
            status: homeLinked ? 'Terhubung' : 'Belum diatur',
            color: homeLinked ? AppColors.safe : AppColors.warning,
            icon: homeLinked ? Icons.home_rounded : Icons.home_outlined,
          ),

          const Divider(height: 20),

          // AI Prediction — cek dari Firestore
          aiAsync.when(
            data: (status) => _StatusRow(
              label: 'AI Prediction',
              status: switch (status) {
                _AiStatus.active => 'Aktif',
                _AiStatus.stale => 'Data Lama',
                _AiStatus.noData => 'Belum Ada Data',
                _AiStatus.noHome => 'Menunggu Rumah',
              },
              color: switch (status) {
                _AiStatus.active => AppColors.primaryOnDark,
                _AiStatus.stale => AppColors.warning,
                _AiStatus.noData => AppColors.danger,
                _AiStatus.noHome => AppColors.danger,
              },
              icon: switch (status) {
                _AiStatus.active => Icons.psychology_rounded,
                _AiStatus.stale => Icons.psychology_outlined,
                _AiStatus.noData => Icons.psychology_outlined,
                _AiStatus.noHome => Icons.psychology_outlined,
              },
            ),
            loading: () => const _StatusRow(
              label: 'AI Prediction',
              status: 'Memeriksa...',
              color: AppColors.warning,
              icon: Icons.psychology_outlined,
            ),
            error: (_, __) => const _StatusRow(
              label: 'AI Prediction',
              status: 'Error',
              color: AppColors.danger,
              icon: Icons.psychology_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String status;
  final Color color;
  final IconData icon;

  const _StatusRow({
    required this.label,
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withAlpha(120), blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
