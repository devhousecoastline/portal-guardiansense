import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:guardian_portal/features/account/data/user_repository.dart';
import 'package:guardian_portal/features/auth/application/auth_controller.dart';
import 'package:guardian_portal/features/info/domain/portal_privacy_consent.dart';
import 'package:guardian_portal/features/info/domain/privacy_policy.dart';

/// Observa o aceite da política da conta logada e avisa o router.
class PrivacyConsentController extends ChangeNotifier {
  PrivacyConsentController({
    required AuthController auth,
    UserRepository? users,
  })  : _auth = auth,
        _users = users ?? UserRepository() {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final AuthController _auth;
  final UserRepository _users;

  StreamSubscription<PortalPrivacyConsent>? _subscription;
  String? _uid;
  bool _ready = false;
  PortalPrivacyConsent _consent = const PortalPrivacyConsent();

  bool get isReady => _ready;

  bool get hasAcceptedCurrent =>
      _ready && _consent.hasAccepted(PrivacyPolicy.version);

  void _onAuthChanged() {
    final uid = _auth.user?.uid;
    if (uid == _uid) return;
    _uid = uid;
    unawaited(_subscription?.cancel());
    _subscription = null;

    if (uid == null) {
      _ready = true;
      _consent = const PortalPrivacyConsent();
      notifyListeners();
      return;
    }

    _ready = false;
    _consent = const PortalPrivacyConsent();
    notifyListeners();

    _subscription = _users.watchPortalPrivacyConsent(uid).listen(
      (consent) {
        _consent = consent;
        _ready = true;
        notifyListeners();
      },
      onError: (_) {
        _consent = const PortalPrivacyConsent();
        _ready = true;
        notifyListeners();
      },
    );
  }

  Future<void> acceptCurrentPolicy() async {
    final uid = _uid;
    if (uid == null) return;
    await _users.acceptPortalPrivacyPolicy(
      uid: uid,
      version: PrivacyPolicy.version,
    );
    _consent = PortalPrivacyConsent(
      version: PrivacyPolicy.version,
      acceptedAt: DateTime.now().toUtc(),
    );
    _ready = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
