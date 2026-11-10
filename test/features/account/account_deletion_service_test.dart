import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/account/data/account_deletion_service.dart';

void main() {
  AccountDeletionFailure failureFor(String code) =>
      AccountDeletionException.failureForCode(code);

  test('login antigo pede para entrar de novo (web e nativo)', () {
    expect(
      failureFor('failed-precondition'),
      AccountDeletionFailure.requiresRecentLogin,
    );
    expect(
      failureFor('functions/failed-precondition'),
      AccountDeletionFailure.requiresRecentLogin,
    );
    expect(
      failureFor('FAILED_PRECONDITION'),
      AccountDeletionFailure.requiresRecentLogin,
    );
  });

  test('sessão perdida, sem rede e genérico', () {
    expect(
      failureFor('unauthenticated'),
      AccountDeletionFailure.unauthenticated,
    );
    expect(failureFor('unavailable'), AccountDeletionFailure.network);
    expect(failureFor('deadline-exceeded'), AccountDeletionFailure.network);
    expect(failureFor('internal'), AccountDeletionFailure.unknown);
    expect(failureFor('not-found'), AccountDeletionFailure.unknown);
  });
}
