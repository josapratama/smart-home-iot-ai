import 'package:flutter/material.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class DashboardAppBar extends StatelessWidget {
  final String firstName;
  final String? photoUrl;
  final bool hasActiveAlarm;
  final VoidCallback onAlarmTap;
  final VoidCallback onAvatarTap;

  const DashboardAppBar({
    super.key,
    required this.firstName,
    this.photoUrl,
    required this.hasActiveAlarm,
    required this.onAlarmTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $firstName 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pantau rumah Anda',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      _AppBarIconBtn(
                        icon: Icons.notifications_outlined,
                        onTap: onAlarmTap,
                        badge: hasActiveAlarm,
                      ),
                      const SizedBox(width: 8),
                      _UserAvatar(photoUrl: photoUrl, onTap: onAvatarTap),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── App Bar Icon Button ──────────────────────────────────────────────────

class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _AppBarIconBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (badge)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── User Avatar ──────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onTap;

  const _UserAvatar({this.photoUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: photoUrl != null
              ? Image.network(photoUrl!, fit: BoxFit.cover)
              : const Icon(Icons.person_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
