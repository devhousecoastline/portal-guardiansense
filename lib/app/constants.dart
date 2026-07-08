/// Constantes globais do portal web.
abstract final class AppConstants {
  static const String appName = 'Guardian Sense';
  static const String portalTitle = 'Centro de Segurança';
  static const String tagline =
      'Seu aparelho continua protegido mesmo quando você não está com ele.';
  static const String loginHeadline = tagline;
  static const String loginDescription =
      'O Guardian Sense monitora continuamente sinais de furto e protege '
      'automaticamente seus aplicativos e dados.';
  static const String loginCardSubtitle =
      'Entre para acompanhar seus dispositivos protegidos.';
  static const String footerTagline =
      'Proteção inteligente para seus ativos digitais.';
  static const String appVersion = 'v1.0';
  static const String copyrightHolder = 'devhousecoastline';

  static const List<String> loginFeatures = [
    'Detecção inteligente',
    'Proteção offline',
    'Recuperação por biometria',
    'App Locker',
    'Contenção automática',
    'Monitoramento contínuo',
  ];

  /// Largura máxima do layout desktop da login.
  static const double loginMaxWidth = 1180;

  /// Dispositivo online se `lastSeen` for mais recente que isso (~3× o ciclo do app).
  static const Duration deviceOnlineThreshold = Duration(seconds: 90);

  /// Programa Nacional Celular Seguro (MJSP) — bloqueio de IMEI/linha na operadora.
  static const String celularSeguroUrl = 'https://celularseguro.mj.gov.br/';
}
