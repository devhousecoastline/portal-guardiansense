import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/account/domain/user_plan.dart';

void main() {
  test('subscription active + plan free → premium, limite 1, sem upgrade', () {
    final plan = UserPlan.fromFirestore({
      'plan': 'free',
      'subscription': {
        'status': 'active',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      },
    });

    expect(plan.plan, 'premium');
    expect(plan.deviceLimit, 1);
    expect(plan.isEntitled, isTrue);
    expect(plan.isFree, isFalse);
  });

  test('plan free sem subscription active → limite 1, upgrade permitido', () {
    final plan = UserPlan.fromFirestore({
      'plan': 'free',
      'subscription': {'status': 'trial'},
    });

    expect(plan.isEntitled, isFalse);
    expect(plan.isFree, isTrue);
    expect(plan.deviceLimit, 1);
  });
}
