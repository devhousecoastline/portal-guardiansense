import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/navigation/navigation_shell.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/features/account/presentation/account_page.dart';
import 'package:guardian_portal/features/auth/presentation/login_page.dart';
import 'package:guardian_portal/features/dashboard/presentation/dashboard_page.dart';
import 'package:guardian_portal/features/devices/presentation/devices_page.dart';
import 'package:guardian_portal/features/events/presentation/events_details_page.dart';
import 'package:guardian_portal/features/events/presentation/events_page.dart';
import 'package:guardian_portal/features/info/application/privacy_consent_controller.dart';
import 'package:guardian_portal/features/info/application/privacy_consent_redirect.dart';
import 'package:guardian_portal/features/info/presentation/privacy_consent_page.dart';
import 'package:guardian_portal/features/info/presentation/privacy_page.dart';
import 'package:guardian_portal/features/locate/presentation/locate_page.dart';
import 'package:guardian_portal/features/settings/presentation/settings_page.dart';
import 'package:guardian_portal/features/subscription/presentation/premium_page.dart';

GoRouter createAppRouter({
  required Listenable authListenable,
  required PrivacyConsentController consent,
}) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: Listenable.merge([authListenable, consent]),
    redirect: (context, state) {
      return resolveAuthRedirect(
        signedIn: FirebaseAuth.instance.currentUser != null,
        consentReady: consent.isReady,
        hasAcceptedCurrentPolicy: consent.hasAcceptedCurrent,
        path: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        redirect: (context, state) => AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final creating = state.uri.queryParameters['criar'] == '1';
          return LoginPage(initialCreating: creating);
        },
      ),
      GoRoute(
        path: AppRoutes.privacyConsent,
        builder: (context, state) => const PrivacyConsentPage(),
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
            path: '${AppRoutes.eventsDetails}/:day',
            redirect: (context, state) {
              final day = AppRoutes.parseEventsDay(
                state.pathParameters['day'],
              );
              if (day == null) return AppRoutes.events;
              return null;
            },
            builder: (context, state) {
              final day = AppRoutes.parseEventsDay(
                state.pathParameters['day'],
              )!;
              return EventsDetailsPage(day: day);
            },
          ),
          GoRoute(
            // Compat: `#/events-details` sem data → lista
            path: AppRoutes.eventsDetails,
            redirect: (context, state) => AppRoutes.events,
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
            path: AppRoutes.privacy,
            builder: (context, state) => const PrivacyPage(),
          ),
          GoRoute(
            path: AppRoutes.account,
            builder: (context, state) => const AccountPage(),
          ),
          GoRoute(
            path: AppRoutes.premium,
            builder: (context, state) => const PremiumPage(),
          ),
        ],
      ),
    ],
  );
}
