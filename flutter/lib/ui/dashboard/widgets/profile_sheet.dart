import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home/data/repository/auth_repository.dart';
import 'package:smart_home/data/repository/user_repository.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

void showProfileSheet(
  BuildContext context,
  WidgetRef ref, {
  String? name,
  String? email,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ProfileSheet(
      name: name,
      email: email,
      onLogout: () {
        Navigator.pop(context);
        ref.read(authRepositoryProvider).logout();
      },
      homeId: ref.read(homeIdProvider),
    ),
  );
}

class _ProfileSheet extends StatelessWidget {
  final String? name;
  final String? email;
  final String? homeId;
  final VoidCallback onLogout;

  const _ProfileSheet({
    this.name,
    this.email,
    this.homeId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOnDark.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),

          Text(
            name ?? 'Pengguna',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),

          // ── ID Rumah ──────────────────────────────────────────────────
          if (homeId != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryOnDark.withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryOnDark.withAlpha(60),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOnDark.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: AppColors.primaryOnDark,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID Rumah',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Bagikan ke anggota',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryOnDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          homeId!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                            letterSpacing: 0.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      // Tombol salin
                      _IconActionBtn(
                        icon: Icons.copy_rounded,
                        tooltip: 'Salin ID',
                        color: AppColors.primaryOnDark,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: homeId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('ID Rumah disalin!'),
                              backgroundColor: AppColors.primaryOnDark,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Tombol share
                      _IconActionBtn(
                        icon: Icons.share_rounded,
                        tooltip: 'Bagikan',
                        color: AppColors.secondary,
                        onTap: () {
                          // Share via clipboard + snackbar instruksi
                          Clipboard.setData(ClipboardData(text: homeId!));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'ID Rumah "$homeId" disalin.\nBagikan ke anggota untuk bergabung.',
                              ),
                              backgroundColor: AppColors.secondary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Divider(color: isDark ? Colors.white12 : Colors.grey.shade100),
          const SizedBox(height: 16),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.danger, size: 20),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Icon Action Button ───────────────────────────────────────────────────

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _IconActionBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
