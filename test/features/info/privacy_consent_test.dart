import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/features/info/application/privacy_consent_redirect.dart';
import 'package:guardian_portal/features/info/domain/portal_privacy_consent.dart';
import 'package:guardian_portal/features/info/domain/privacy_policy.dart';

void main() {
  group('PortalPrivacyConsent', () {
    test('sem documento exige aceite', () {
      const consent = PortalPrivacyConsent();
      expect(consent.hasAccepted(PrivacyPolicy.version), isFalse);
    });

    test('versão atual libera o portal', () {
      final consent = PortalPrivacyConsent.fromMap({
        'portalPrivacyConsent': {'version': PrivacyPolicy.version},
      });
      expect(consent.hasAccepted(PrivacyPolicy.version), isTrue);
    });

    test('versão antiga pede aceite de novo', () {
      final consent = PortalPrivacyConsent.fromMap({
        'portalPrivacyConsent': {'version': '1.0'},
      });
      expect(consent.hasAccepted(PrivacyPolicy.version), isFalse);
    });
  });

  group('resolveAuthRedirect', () {
    test('auth ainda não pronto não redireciona', () {
      expect(
        resolveAuthRedirect(
          authReady: false,
          signedIn: false,
          consentReady: false,
          hasAcceptedCurrentPolicy: false,
          path: AppRoutes.dashboard,
        ),
        isNull,
      );
    });

    test('deslogado em rotas do app vai para login', () {
      expect(
        resolveAuthRedirect(
          authReady: true,
          signedIn: false,
          consentReady: true,
          hasAcceptedCurrentPolicy: false,
          path: AppRoutes.dashboard,
        ),
        AppRoutes.login,
      );
    });

    test('deslogado permanece na landing e no login', () {
      expect(
        resolveAuthRedirect(
          authReady: true,
          signedIn: false,
          consentReady: true,
          hasAcceptedCurrentPolicy: false,
          path: AppRoutes.home,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          authReady: true,
          signedIn: false,
          consentReady: true,
          hasAcceptedCurrentPolicy: false,
          path: AppRoutes.login,
        ),
        isNull,
      );
    });

    test('logado sem aceite vai para o gate', () {
      expect(
        resolveAuthRedirect(
          authReady: true,
          signedIn: true,
          consentReady: true,
          hasAcceptedCurrentPolicy: false,
          path: AppRoutes.dashboard,
        ),
        AppRoutes.privacyConsent,
      );
    });

    test('logado aguardando Firestore permanece na rota atual', () {
      expect(
        resolveAuthRedirect(
          authReady: true,
          signedIn: true,
          consentReady: false,
          hasAcceptedCurrentPolicy: false,
          path: AppRoutes.events,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          authReady: true,
          signedIn: true,
          consentReady: false,
          hasAcceptedCurrentPolicy: false,
          path: AppRoutes.login,
        ),
        isNull,
      );
    });

    test('com aceite segue para o dashboard após o login', () {
      expect(
        resolveAuthRedirect(
          authReady: true,
          signedIn: true,
          consentReady: true,
          hasAcceptedCurrentPolicy: true,
          path: AppRoutes.login,
        ),
        AppRoutes.dashboard,
      );
    });

    test('com aceite deixa a landing e vai ao dashboard', () {
      expect(
        resolveAuthRedirect(
          authReady: true,
          signedIn: true,
          consentReady: true,
          hasAcceptedCurrentPolicy: true,
          path: AppRoutes.home,
        ),
        AppRoutes.dashboard,
      );
    });

    test('com aceite não volta ao gate', () {
      expect(
        resolveAuthRedirect(
          authReady: true,
          signedIn: true,
          consentReady: true,
          hasAcceptedCurrentPolicy: true,
          path: AppRoutes.privacyConsent,
        ),
        AppRoutes.dashboard,
      );
    });
  });
}
