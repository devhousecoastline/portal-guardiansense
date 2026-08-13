/// Constantes globais do portal web.
abstract final class AppConstants {
  static const String appName = 'Guardian Sense';
  static const String portalTitle = 'Central de Proteção';
  static const String loginCardTitle = 'Acesse sua Central de Proteção';
  static const String tagline =
      'Seu aparelho continua protegido. Mesmo quando está longe de você.';
  static const String loginHeadline = tagline;
  static const String loginDescription =
      'O Guardian Sense monitora continuamente sinais de furto e protege '
      'automaticamente seus aplicativos e dados.';
  static const String loginCardSubtitle =
      'Gerencie sua proteção, dispositivos e alertas em tempo real.';
  static const String loginTrustLine =
      'Proteção inteligente baseada em contexto e risco';
  static const String footerTagline =
      'Proteção inteligente para seus ativos digitais.';

  /// Versão desta Central de Proteção. Independente do app no aparelho.
  ///
  /// Convenção de publicação:
  /// - cada deploy sobe o patch (`1.0.0` → `1.0.1`) e o build (`+1` → `+2`);
  /// - minor/major só em mudança grande de produto.
  /// Manter igual ao `version:` do pubspec.yaml (`x.y.z+build`).
  static const String portalVersion = '1.0.12';
  static const int portalBuild = 13;

  /// Destaques do painel de marca na login (desktop).
  static const List<String> loginHighlights = [
    'Proteção dos seus ativos digitais',
    'Detecção inteligente de risco',
    'Bloqueio automático de apps críticos',
  ];

  /// Largura máxima do layout desktop da login.
  static const double loginMaxWidth = 1180;

  /// Dispositivo online se `lastSeen` for mais recente que isso.
  ///
  /// Alinhado à presença do FGS no app (`ProtectionStateFirestoreSync` ~180s):
  /// limiar ≈ 2× o ciclo. Após desinstalar o app, o portal só marca offline
  /// quando este prazo passa (não há sinal de “aparelho sumiu”).
  static const Duration deviceOnlineThreshold = Duration(minutes: 4);

  /// Programa Nacional Celular Seguro (MJSP) — bloqueio de IMEI/linha na operadora.
  static const String celularSeguroUrl = 'https://celularseguro.mj.gov.br/';
}
