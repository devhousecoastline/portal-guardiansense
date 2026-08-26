import 'package:cloud_firestore/cloud_firestore.dart';

/// Plano do usuário — define quantos aparelhos físicos o portal exibe.
class UserPlan {
  const UserPlan({
    required this.plan,
    required this.deviceLimit,
    this.isEntitled = false,
  });

  final String plan;
  final int deviceLimit;

  /// Assinatura paga/trial ativo — não mostrar CTA de upgrade na lista.
  final bool isEntitled;

  bool get isFree => !isEntitled && plan == 'free';

  static const free = UserPlan(plan: 'free', deviceLimit: 1);

  factory UserPlan.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return UserPlan.free;

    final entitled = _subscriptionGrantsPremium(data);
    final plan = data['plan'] as String? ?? 'free';
    final explicit = (data['deviceLimit'] as num?)?.toInt();

    final limit = entitled
        ? (explicit ?? 1).clamp(1, 99)
        : (explicit ??
                switch (plan) {
                  'pro' => 5,
                  'family' => 10,
                  _ => 1,
                })
            .clamp(1, 99);
    final resolvedPlan = entitled && plan == 'free' ? 'premium' : plan;

    return UserPlan(
      plan: resolvedPlan,
      deviceLimit: limit,
      isEntitled: entitled,
    );
  }

  /// PIX / Play gravam `subscription.status=active`; o campo raiz `plan` pode
  /// ficar desatualizado (`free`) até o app sincronizar.
  static bool _subscriptionGrantsPremium(Map<String, dynamic> data) {
    final sub = data['subscription'];
    if (sub is! Map) return false;
    final status = sub['status'] as String?;
    if (status != 'active') return false;
    final expires = _readDate(sub['expiresAt']);
    if (expires != null && DateTime.now().isAfter(expires)) return false;
    return true;
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
