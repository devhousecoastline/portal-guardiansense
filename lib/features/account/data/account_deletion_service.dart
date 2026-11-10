import 'package:cloud_functions/cloud_functions.dart';

/// Motivos de falha da callable `deleteAccount` — mesmo mapeamento do app.
enum AccountDeletionFailure {
  /// `failed-precondition`: login antigo, pedir para entrar de novo.
  requiresRecentLogin,

  /// `unauthenticated`: sessão perdida.
  unauthenticated,

  /// `unavailable` / `deadline-exceeded`: sem rede.
  network,

  unknown,
}

final class AccountDeletionException implements Exception {
  const AccountDeletionException(this.failure);

  final AccountDeletionFailure failure;

  /// Web devolve `functions/failed-precondition`; nativo, `FAILED_PRECONDITION`.
  static AccountDeletionFailure failureForCode(String code) {
    final normalized = code
        .trim()
        .toLowerCase()
        .replaceFirst('functions/', '')
        .replaceAll('_', '-');
    return switch (normalized) {
      'failed-precondition' => AccountDeletionFailure.requiresRecentLogin,
      'unauthenticated' => AccountDeletionFailure.unauthenticated,
      'unavailable' || 'deadline-exceeded' => AccountDeletionFailure.network,
      _ => AccountDeletionFailure.unknown,
    };
  }

  @override
  String toString() => 'AccountDeletionException(${failure.name})';
}

/// Exclui a conta logada no servidor (`deleteAccount`, Admin SDK).
class AccountDeletionService {
  AccountDeletionService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFunctions _functions;

  Future<void> deleteAccount() async {
    try {
      await _functions.httpsCallable('deleteAccount').call<Object?>();
    } on FirebaseFunctionsException catch (e) {
      throw AccountDeletionException(
        AccountDeletionException.failureForCode(e.code),
      );
    }
  }
}
