import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home/ui/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const _tabs = [
    _TabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    _TabItem(
      icon: Icons.devices_outlined,
      activeIcon: Icons.devices_rounded,
      label: 'Perangkat',
    ),
    _TabItem(
      icon: Icons.bolt_outlined,
      activeIcon: Icons.bolt_rounded,
      label: 'Energi',
    ),
    _TabItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Alarm',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 60 : 20),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = current == i;
                return _NavItem(
                  tab: tab,
                  isActive: isActive,
                  onTap: () => navigationShell.goBranch(
                    i,
                    initialLocation: i == navigationShell.currentIndex,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavItem extends StatelessWidget {
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? AppColors.safe.withAlpha(30) // highlight terang di dark
                  : AppColors.primaryOnDark.withAlpha(20))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? tab.activeIcon : tab.icon,
                key: ValueKey(isActive),
                color: isActive
                    ? AppColors.safe // terang di dark bg
                    : (isDark ? Colors.white38 : Colors.grey.shade500),
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        tab.label,
                        style: TextStyle(
                          color: isDark ? AppColors.primaryOnDark : AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
