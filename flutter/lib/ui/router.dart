import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home/ui/auth/login_screen.dart';
import 'package:smart_home/ui/auth/register_screen.dart';
import 'package:smart_home/ui/dashboard/dashboard_screen.dart';
import 'package:smart_home/ui/device/device_control_screen.dart';
import 'package:smart_home/ui/alarm/alarm_screen.dart';
import 'package:smart_home/ui/energy/energy_screen.dart';
import 'package:smart_home/ui/shell/main_shell.dart';
import 'package:smart_home/ui/home_setup/home_setup_screen.dart';
import 'package:smart_home/data/repository/auth_repository.dart';
import 'package:smart_home/data/repository/user_repository.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSetupRoute = state.matchedLocation == '/setup-home';

      // Belum login → ke login
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // Sudah login tapi di auth route → ke dashboard
      if (isLoggedIn && isAuthRoute) return '/dashboard';

      // Profil sudah dimuat dari network, sudah login, tapi belum punya homeId
      // TIDAK redirect ke setup dari sini — biarkan dashboard yang handle
      // agar tidak false-redirect saat Firestore masih loading dari cache

      // Sudah setup → jangan balik ke setup
      if (isLoggedIn && isSetupRoute) {
        final currentHomeId = profileAsync.valueOrNull?.homeId;
        if (currentHomeId != null) return '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // Setup rumah
      GoRoute(
        path: '/setup-home',
        builder: (_, __) => const HomeSetupScreen(),
      ),

      // Main app dengan bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),

          // Tab 1: Perangkat
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/device',
                // Tidak pass deviceId — screen ambil homeId dari userProfileProvider
                builder: (_, __) => const DeviceControlScreen(deviceId: ''),
                routes: [
                  GoRoute(
                    path: ':deviceId',
                    builder: (_, state) => DeviceControlScreen(
                      deviceId: state.pathParameters['deviceId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 2: Energi
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/energy',
                builder: (_, __) => const EnergyScreen(),
              ),
            ],
          ),

          // Tab 3: Alarm
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alarm',
                builder: (_, __) => const AlarmScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
