import 'package:guardian_portal/core/routing/app_routes.dart';

/// Redirect de auth + consentimento. Puro, para testar sem GoRouter.
String? resolveAuthRedirect({
  required bool signedIn,
  required bool consentReady,
  required bool hasAcceptedCurrentPolicy,
  required String path,
}) {
  if (path == AppRoutes.home) return AppRoutes.login;

  if (!signedIn) {
    return path == AppRoutes.login ? null : AppRoutes.login;
  }

  if (!consentReady || !hasAcceptedCurrentPolicy) {
    return path == AppRoutes.privacyConsent ? null : AppRoutes.privacyConsent;
  }

  if (path == AppRoutes.login || path == AppRoutes.privacyConsent) {
    return AppRoutes.dashboard;
  }
  return null;
}
