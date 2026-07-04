/// Constantes globais do portal web.
abstract final class AppConstants {
  static const String appName = 'Guardian Sense';
  static const String portalTitle = 'Centro de Segurança';
  static const String tagline =
      'Seu aparelho continua protegido mesmo quando não está mais nas suas mãos.';

  /// Dispositivo considerado online se `lastSeen` for mais recente que isso.
  static const Duration deviceOnlineThreshold = Duration(minutes: 5);
}
