import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/account/domain/user_plan.dart';
import 'package:guardian_portal/features/subscription/domain/premium_features.dart';

void main() {
  test('Eventos liberado com assinatura premium ativa', () {
    final plan = UserPlan.fromFirestore({
      'plan': 'free',
      'subscription': {
        'status': 'active',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      },
    });

    expect(PremiumFeatures.events(plan), isTrue);
  });

  test('Eventos bloqueado no plano free', () {
    final plan = UserPlan.fromFirestore({
      'plan': 'free',
      'subscription': {'status': 'trial'},
    });

    expect(PremiumFeatures.events(plan), isFalse);
    expect(PremiumFeatures.locate(plan), isFalse);
  });

  test('Localizar liberado com assinatura premium ativa', () {
    final plan = UserPlan.fromFirestore({
      'plan': 'premium',
      'subscription': {
        'status': 'active',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      },
    });

    expect(PremiumFeatures.locate(plan), isTrue);
  });

  test('Proteger todos bloqueado no plano free', () {
    final plan = UserPlan.fromFirestore({'plan': 'free'});

    expect(PremiumFeatures.remoteProtectAll(plan), isFalse);
  });

  test('Proteger extras (2º+) bloqueado no plano free', () {
    final plan = UserPlan.fromFirestore({'plan': 'free'});

    expect(PremiumFeatures.remoteProtectExtra(plan), isFalse);
  });

  test('Fechar ostra bloqueado no plano free', () {
    final plan = UserPlan.fromFirestore({'plan': 'free'});

    expect(PremiumFeatures.closeOyster(plan), isFalse);
  });
}
