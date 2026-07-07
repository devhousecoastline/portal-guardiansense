import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/navigation/navigation_shell.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/features/account/presentation/account_page.dart';
import 'package:guardian_portal/features/auth/presentation/home_page.dart';
import 'package:guardian_portal/features/auth/presentation/login_page.dart';
import 'package:guardian_portal/features/dashboard/presentation/dashboard_page.dart';
import 'package:guardian_portal/features/devices/presentation/devices_page.dart';
import 'package:guardian_portal/features/events/presentation/events_page.dart';
import 'package:guardian_portal/features/locate/presentation/locate_page.dart';
import 'package:guardian_portal/features/settings/presentation/settings_page.dart';

bool _isPublicRoute(String path) =>
    path == AppRoutes.home || path == AppRoutes.login;

GoRouter createAppRouter({required Listenable authListenable}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final path = state.matchedLocation;
      final onPublicRoute = _isPublicRoute(path);

      if (user == null) {
        return onPublicRoute ? null : AppRoutes.home;
      }
      if (onPublicRoute) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final creating = state.uri.queryParameters['criar'] == '1';
          return LoginPage(initialCreating: creating);
        },
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
