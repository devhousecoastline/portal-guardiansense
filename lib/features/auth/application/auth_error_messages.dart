import 'package:firebase_auth/firebase_auth.dart';

/// Mensagens de erro de login compartilhadas (login e excluir conta).
String authErrorMessage(FirebaseAuthException e) => switch (e.code) {
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        'E-mail ou senha incorretos. Se você entrou pelo Google no app, '
            'use «Continuar com Google».',
      'email-already-in-use' =>
        'Este e-mail já está cadastrado. Se você usa o app com Google, '
            'clique em «Continuar com Google».',
      'weak-password' => 'Senha muito fraca (mínimo 6 caracteres).',
      'invalid-email' => 'E-mail inválido.',
      'popup-closed-by-user' || 'cancelled-popup-request' =>
        'Login com Google cancelado.',
      'timeout' => 'Tempo esgotado. Tente novamente.',
      _ => e.message ?? 'Não foi possível entrar.',
    };

bool isAuthPopupCancelled(Object e) {
  final text = e.toString().toLowerCase();
  return text.contains('popup-closed-by-user') ||
      text.contains('cancelled-popup-request') ||
      text.contains('user cancelled') ||
      text.contains('user canceled');
}
