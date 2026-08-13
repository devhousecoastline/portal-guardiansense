import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/navigation/navigation_shell.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/features/account/presentation/account_page.dart';
import 'package:guardian_portal/features/auth/application/auth_controller.dart';
import 'package:guardian_portal/features/auth/presentation/login_page.dart';
import 'package:guardian_portal/features/dashboard/presentation/dashboard_page.dart';
import 'package:guardian_portal/features/devices/domain/device_pairing.dart';
import 'package:guardian_portal/features/devices/presentation/devices_page.dart';
import 'package:guardian_portal/features/devices/presentation/pair_landing_page.dart';
import 'package:guardian_portal/features/events/presentation/events_details_page.dart';
import 'package:guardian_portal/features/events/presentation/events_page.dart';
import 'package:guardian_portal/features/info/application/privacy_consent_controller.dart';
import 'package:guardian_portal/features/info/application/privacy_consent_redirect.dart';
import 'package:guardian_portal/features/info/presentation/about_page.dart';
import 'package:guardian_portal/features/info/presentation/coming_soon_page.dart';
import 'package:guardian_portal/features/info/presentation/privacy_consent_page.dart';
import 'package:guardian_portal/features/info/presentation/privacy_page.dart';
import 'package:guardian_portal/features/locate/presentation/locate_page.dart';
import 'package:guardian_portal/features/settings/presentation/settings_page.dart';
import 'package:guardian_portal/features/subscription/presentation/premium_page.dart';

GoRouter createAppRouter({
  required AuthController auth,
  required PrivacyConsentController consent,
}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: Listenable.merge([auth, consent]),
    redirect: (context, state) {
      return resolveAuthRedirect(
        authReady: auth.isReady,
        signedIn: auth.isSignedIn,
        consentReady: consent.isReady,
        hasAcceptedCurrentPolicy: consent.hasAcceptedCurrent,
        path: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => AppConstants.showComingSoonLanding
            ? const ComingSoonPage()
            : const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final creating = state.uri.queryParameters['criar'] == '1';
          return LoginPage(initialCreating: creating);
        },
      ),
      GoRoute(
        path: AppRoutes.pair,
        builder: (context, state) {
          return PairLandingPage(
            code: state.uri.queryParameters[DevicePairing.codeQueryParam],
          );
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
            path: AppRoutes.about,
            builder: (context, state) => const AboutPage(),
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
