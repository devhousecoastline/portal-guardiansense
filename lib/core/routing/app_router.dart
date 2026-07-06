import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/navigation/navigation_shell.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/features/account/presentation/account_page.dart';
import 'package:guardian_portal/features/auth/presentation/login_page.dart';
import 'package:guardian_portal/features/dashboard/presentation/dashboard_page.dart';
import 'package:guardian_portal/features/devices/presentation/devices_page.dart';
import 'package:guardian_portal/features/events/presentation/events_page.dart';
import 'package:guardian_portal/features/locate/presentation/locate_page.dart';
import 'package:guardian_portal/features/settings/presentation/settings_page.dart';

GoRouter createAppRouter({required Listenable authListenable}) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final loggingIn = state.matchedLocation == AppRoutes.login;

      if (user == null) return loggingIn ? null : AppRoutes.login;
      if (loggingIn) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.events,
            builder: (context, state) => const EventsPage(),
          ),
          GoRoute(
            path: AppRoutes.locate,
            builder: (context, state) => const LocatePage(),
          ),
          GoRoute(
            path: AppRoutes.devices,
            builder: (context, state) => const DevicesPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.account,
            builder: (context, state) => const AccountPage(),
          ),
        ],
      ),
    ],
  );
}
