import 'package:guardian_portal/core/routing/app_routes.dart';

/// Redirect de auth + consentimento. Puro, para testar sem GoRouter.
String? resolveAuthRedirect({
  required bool authReady,
  required bool signedIn,
  required bool consentReady,
  required bool hasAcceptedCurrentPolicy,
  required String path,
}) {
  if (path == AppRoutes.home) return AppRoutes.login;

  // Sessão Firebase ainda não restaurou — não manda para login no refresh.
  if (!authReady) {
    return null;
  }

  if (!signedIn) {
    return path == AppRoutes.login ? null : AppRoutes.login;
  }

  // Firestore ainda não respondeu: fica na rota atual.
  // Não manda para login nem monta o gate — evita flash no refresh
  // e o flash do aceite para quem já aceitou.
  if (!consentReady) {
    return null;
  }

  if (!hasAcceptedCurrentPolicy) {
    return path == AppRoutes.privacyConsent ? null : AppRoutes.privacyConsent;
  }

  if (path == AppRoutes.login || path == AppRoutes.privacyConsent) {
    return AppRoutes.dashboard;
  }
  return null;
}
