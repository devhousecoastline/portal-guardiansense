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

  // Sem resposta do Firestore ainda: não monta o gate — evita flash da
  // tela de aceite para quem já aceitou a versão atual.
  if (!consentReady) {
    if (path == AppRoutes.login || path == AppRoutes.privacyConsent) {
      return null;
    }
    return AppRoutes.login;
  }

  if (!hasAcceptedCurrentPolicy) {
    return path == AppRoutes.privacyConsent ? null : AppRoutes.privacyConsent;
  }

  if (path == AppRoutes.login || path == AppRoutes.privacyConsent) {
    return AppRoutes.dashboard;
  }
  return null;
}
