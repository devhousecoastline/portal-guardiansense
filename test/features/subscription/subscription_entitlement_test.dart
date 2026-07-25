import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/subscription/domain/subscription_entitlement.dart';

void main() {
  group('SubscriptionEntitlement', () {
    test('trial válido libera entitlement', () {
      final now = DateTime(2026, 7, 24, 12);
      final e = SubscriptionEntitlement(
        status: SubscriptionStatus.trial,
        trialStartedAt: now,
        trialEndsAt: now.add(const Duration(days: 7)),
      );
      expect(e.isEntitledAt(now), isTrue);
      expect(e.effectiveStatusAt(now), SubscriptionStatus.trial);
      expect(e.trialDaysLeftCeil(now), 7);
    });

    test('trial vencido vira expired', () {
      final start = DateTime(2026, 7, 1);
      final e = SubscriptionEntitlement(
        status: SubscriptionStatus.trial,
        trialStartedAt: start,
        trialEndsAt: start.add(const Duration(days: 7)),
      );
      expect(
        e.effectiveStatusAt(DateTime(2026, 7, 10)),
        SubscriptionStatus.expired,
      );
      expect(e.isEntitledAt(DateTime(2026, 7, 10)), isFalse);
    });

    test('active com expiresAt futuro libera', () {
      final now = DateTime(2026, 7, 24);
      final e = SubscriptionEntitlement(
        status: SubscriptionStatus.active,
        trialStartedAt: now.subtract(const Duration(days: 10)),
        trialEndsAt: now.subtract(const Duration(days: 3)),
        startedAt: now,
        expiresAt: now.add(const Duration(days: 365)),
        store: 'pix',
      );
      expect(e.isEntitledAt(now), isTrue);
      expect(e.effectiveStatusAt(now), SubscriptionStatus.active);
    });
  });
}
