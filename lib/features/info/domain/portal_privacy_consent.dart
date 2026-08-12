/// Aceite da política no portal — gravado em `users/{uid}.portalPrivacyConsent`.
///
/// Independente do aceite local do app. Pede de novo quando [version]
/// diverge da política vigente.
final class PortalPrivacyConsent {
  const PortalPrivacyConsent({this.version, this.acceptedAt});

  static const String firestoreField = 'portalPrivacyConsent';

  final String? version;
  final DateTime? acceptedAt;

  bool hasAccepted(String currentVersion) =>
      version != null && version == currentVersion;

  factory PortalPrivacyConsent.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const PortalPrivacyConsent();
    final raw = data[firestoreField];
    if (raw is! Map) return const PortalPrivacyConsent();
    final map = Map<String, dynamic>.from(raw);
    return PortalPrivacyConsent(
      version: (map['version'] as String?)?.trim(),
      acceptedAt: _parseDate(map['acceptedAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
