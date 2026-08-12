import 'package:flutter/material.dart';
import 'package:guardian_portal/features/info/application/privacy_consent_controller.dart';

class PrivacyConsentScope extends InheritedNotifier<PrivacyConsentController> {
  const PrivacyConsentScope({
    super.key,
    required PrivacyConsentController controller,
    required super.child,
  }) : super(notifier: controller);

  static PrivacyConsentController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PrivacyConsentScope>();
    assert(scope != null, 'PrivacyConsentScope não encontrado');
    return scope!.notifier!;
  }
}
