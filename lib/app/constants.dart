/// Constantes globais do portal web.
abstract final class AppConstants {
  static const String appName = 'Guardian Sense';
  static const String portalTitle = 'Central de Proteção';
  static const String loginCardTitle = 'Já tem o app? Entre';
  static const String tagline =
      'Seu celular continua protegido. Mesmo quando está longe de você.';
  static const String loginCardSubtitle =
      'Use a mesma conta do Guardian Sense no celular.';
  static const String loginStoreCta = 'Baixar na Play Store';
  static const String loginStoreTooltip =
      'Por enquanto, o app está disponível só no Android.';
  static const String footerTagline =
      'Proteção inteligente para seus ativos digitais.';

  /// Versão desta Central de Proteção. Independente do app no aparelho.
  ///
  /// Convenção de publicação:
  /// - cada deploy sobe o patch (`1.0.0` → `1.0.1`) e o build (`+1` → `+2`);
  /// - minor/major só em mudança grande de produto.
  /// Manter igual ao `version:` do pubspec.yaml (`x.y.z+build`).
  static const String portalVersion = '1.0.45';
  static const int portalBuild = 46;

  /// Landing "Em desenvolvimento" na `/`.
  ///
  /// `false` enquanto testamos o portal (login na home).
  /// Voltar para `true` antes do próximo deploy público.
  static const bool showComingSoonLanding = false;

  /// Destaques do painel de marca na login.
  static const List<String> loginHighlights = [
    'Se o celular for levado, os apps críticos que você configurou ficam sem acesso.',
    'Localize o celular e acompanhe o que aconteceu, tudo do portal.',
    'Veja no portal o status, os alertas e a proteção do seu celular.',
  ];

  /// Largura máxima do layout desktop da login.
  static const double loginMaxWidth = 1180;

  /// Cadência de presença quando o doc não traz `presenceIntervalSec`.
  ///
  /// APK sem presença adaptativa grava `lastSeen` a cada ~180s.
  static const Duration presenceIntervalFallback = Duration(seconds: 180);

  /// Online se `agora - lastSeen < presenceOnlineFactor × intervalo`.
  ///
  /// Ostra aberta (600s): 25 min · ostra fechada (180s): 7,5 min. Após
  /// desinstalar o app, o portal só marca offline quando o prazo passa.
  static const double presenceOnlineFactor = 2.5;

  /// Entre o limiar online e este, mostra "última comunicação há N min";
  /// depois, offline. Prazo = `max(presenceOfflineMin, fator × intervalo)`:
  /// ostra aberta (600s): 60 min · ostra fechada (180s): 20 min.
  static const int presenceOfflineFactor = 6;
  static const Duration presenceOfflineMin = Duration(minutes: 20);

  /// Programa Nacional Celular Seguro (MJSP) — bloqueio de IMEI/linha na operadora.
  static const String celularSeguroUrl = 'https://celularseguro.mj.gov.br/';

  /// Ficha do app no Google Play (`applicationId` alinhado ao bundle iOS).
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.guardiansense.app';

  /// Tiles CARTO Voyager na tela Localizar.
  ///
  /// Pedida em https://carto.com/basemaps/apikey (basemap, não o trial da
  /// plataforma). Visível no cliente — igual à apiKey do Firebase.
  static const String cartoBasemapApiKey =
      'cb1_29ip_1_ea9b081a8ef825c9d64ce59a';
}
