/// Estado comercial da conta (trial / assinatura) — alinhado ao app.
enum SubscriptionStatus {
  trial,
  active,
  expired,
  lapsed,
}

/// Snapshot de entitlement em `users/{uid}.subscription`.
final class SubscriptionEntitlement {
  const SubscriptionEntitlement({
    required this.status,
    required this.trialStartedAt,
    required this.trialEndsAt,
    this.startedAt,
    this.expiresAt,
    this.plan = 'annual_12m',
    this.store,
    this.pixPaymentId,
  });

  final SubscriptionStatus status;
  final DateTime trialStartedAt;
  final DateTime trialEndsAt;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String plan;
  final String? store;
  final String? pixPaymentId;

  static const trialDuration = Duration(days: 7);
  static const annualDuration = Duration(days: 365);

  bool isEntitledAt(DateTime now) {
    switch (effectiveStatusAt(now)) {
      case SubscriptionStatus.trial:
      case SubscriptionStatus.active:
        return true;
      case SubscriptionStatus.expired:
      case SubscriptionStatus.lapsed:
        return false;
    }
  }

  SubscriptionStatus effectiveStatusAt(DateTime now) {
    if (status == SubscriptionStatus.active) {
      final end = expiresAt;
      if (end != null && !now.isBefore(end)) {
        return SubscriptionStatus.lapsed;
      }
      return SubscriptionStatus.active;
    }
    if (status == SubscriptionStatus.trial) {
      if (!now.isBefore(trialEndsAt)) {
        return SubscriptionStatus.expired;
      }
      return SubscriptionStatus.trial;
    }
    return status;
  }

  int trialDaysLeftCeil(DateTime now) {
    if (effectiveStatusAt(now) != SubscriptionStatus.trial) return 0;
    final ms = trialEndsAt.difference(now).inMilliseconds;
    if (ms <= 0) return 0;
    const dayMs = 24 * 60 * 60 * 1000;
    return ((ms + dayMs - 1) ~/ dayMs).clamp(1, 7);
  }

  factory SubscriptionEntitlement.newTrial(DateTime now) {
    return SubscriptionEntitlement(
      status: SubscriptionStatus.trial,
      trialStartedAt: now,
      trialEndsAt: now.add(trialDuration),
    );
  }
}
