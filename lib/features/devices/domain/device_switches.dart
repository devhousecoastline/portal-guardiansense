import 'package:cloud_firestore/cloud_firestore.dart';

/// Cota de trocas de aparelho — espelho read-only de `users/{uid}.deviceSwitches`.
///
/// Fonte de verdade: app (`docs/subscription_trial_7d.md`).
final class DeviceSwitches {
  const DeviceSwitches({
    required this.periodStart,
    required this.periodEnd,
    required this.used,
    required this.included,
    required this.extraPurchased,
  });

  static const includedForTrial = 1;
  static const includedForAnnual = 2;
  static const periodLength = Duration(days: 365);

  final DateTime periodStart;
  final DateTime periodEnd;
  final int used;
  final int included;
  final int extraPurchased;

  int get allowance => included + extraPurchased;

  bool get canSwitch => used < allowance;

  int get remaining => (allowance - used).clamp(0, allowance);

  DeviceSwitches ensureCurrentPeriod(DateTime now) {
    if (now.isBefore(periodEnd)) return this;
    return DeviceSwitches(
      periodStart: now,
      periodEnd: now.add(periodLength),
      used: 0,
      included: included,
      extraPurchased: 0,
    );
  }

  static int includedForStatus(String? subscriptionStatus) {
    if (subscriptionStatus == 'trial') return includedForTrial;
    return includedForAnnual;
  }

  factory DeviceSwitches.fresh({
    required DateTime now,
    required int included,
  }) {
    return DeviceSwitches(
      periodStart: now,
      periodEnd: now.add(periodLength),
      used: 0,
      included: included,
      extraPurchased: 0,
    );
  }

  /// Lê o mapa Firestore e normaliza o período (igual ao app).
  factory DeviceSwitches.resolve(
    Map<String, dynamic>? raw, {
    required DateTime now,
    required int defaultIncluded,
  }) {
    if (raw == null || raw.isEmpty) {
      return DeviceSwitches.fresh(now: now, included: defaultIncluded);
    }

    final start = _readDate(raw['periodStart']) ?? now;
    final end = _readDate(raw['periodEnd']) ?? start.add(periodLength);
    final used = (raw['used'] as num?)?.toInt() ?? 0;
    final included = (raw['included'] as num?)?.toInt() ?? defaultIncluded;
    final extra = (raw['extraPurchased'] as num?)?.toInt() ?? 0;

    return DeviceSwitches(
      periodStart: start,
      periodEnd: end,
      used: used < 0 ? 0 : used,
      included: included < 0 ? defaultIncluded : included,
      extraPurchased: extra < 0 ? 0 : extra,
    ).ensureCurrentPeriod(now);
  }

  /// Lê do doc `users/{uid}` (subscription + deviceSwitches).
  factory DeviceSwitches.fromUserDoc(
    Map<String, dynamic>? data, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now().toUtc();
    final sub = data?['subscription'];
    String? status;
    if (sub is Map) {
      status = sub['status'] as String?;
    }
    final included = includedForStatus(status);
    final raw = data?['deviceSwitches'];
    Map<String, dynamic>? normalized;
    if (raw is Map) {
      normalized = Map<String, dynamic>.from(raw);
    }
    return DeviceSwitches.resolve(
      normalized,
      now: reference,
      defaultIncluded: included,
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }
}
