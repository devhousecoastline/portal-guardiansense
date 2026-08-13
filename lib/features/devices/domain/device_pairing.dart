import 'package:cloud_firestore/cloud_firestore.dart';

/// Desafio de identidade para vincular o aparelho à conta logada no portal.
///
/// O QR aponta para [pairingUrl]. O app confirma via callable
/// `confirmDevicePairing` — o cliente não pode marcar `verified` sozinho.
final class DevicePairing {
  const DevicePairing({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    required this.used,
    this.deviceId,
  });

  static const ttl = Duration(minutes: 5);
  static const publicOrigin = 'https://guardian-sense.com';
  static const codeQueryParam = 'c';

  /// Alfabeto sem 0/O/1/I/L — o mesmo da Function.
  static const codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const codeLength = 6;

  final String id;
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool used;
  final String? deviceId;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  bool isActiveAt(DateTime now) => !used && !isExpiredAt(now);

  String get pairingUrl => uriFor(code);

  static String uriFor(String code) {
    final normalized = normalizeCode(code);
    return '$publicOrigin/pair?$codeQueryParam=$normalized';
  }

  /// Aceita o código cru ou a URL completa do QR.
  static String? parseCode(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      final fromQuery = uri.queryParameters[codeQueryParam];
      if (fromQuery != null) return normalizeCode(fromQuery);
    }

    return normalizeCode(trimmed);
  }

  static String normalizeCode(String raw) {
    return raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z2-9]'), '');
  }

  static bool isWellFormedCode(String code) {
    if (code.length != codeLength) return false;
    return code.split('').every(codeAlphabet.contains);
  }

  factory DevicePairing.fromMap(String id, Map<String, dynamic> data) {
    return DevicePairing(
      id: id,
      code: normalizeCode(data['code'] as String? ?? ''),
      createdAt: _date(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: _date(data['expiresAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      used: data['used'] as bool? ?? false,
      deviceId: data['deviceId'] as String?,
    );
  }

  factory DevicePairing.fromCallable(Map<String, dynamic> map) {
    final id = map['pairingId'] as String? ?? '';
    final code = normalizeCode(map['code'] as String? ?? '');
    final expiresMs = (map['expiresAtMs'] as num?)?.toInt() ?? 0;
    return DevicePairing(
      id: id,
      code: code,
      createdAt: DateTime.now().toUtc(),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresMs, isUtc: true),
      used: false,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    return null;
  }
}
