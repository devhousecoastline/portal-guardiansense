/// Situação / contexto situacional publicado pelo app (Guardian Context Engine).
///
/// IDs de wire — copy PT alinhada ao app (`SituationStatusLine`). Portal só exibe.
enum DeviceSituation {
  home,
  trusted,
  street,
  transit,
  unknown;

  /// Label curto (igual ao app).
  String get labelPt => switch (this) {
        DeviceSituation.home => 'Casa',
        DeviceSituation.trusted => 'Trabalho',
        DeviceSituation.street => 'Rua',
        DeviceSituation.transit => 'Deslocamento',
        DeviceSituation.unknown => 'Ambiente em análise',
      };

  /// Hint ao lado do label (igual ao app).
  String get hintPt => switch (this) {
        DeviceSituation.home => 'Ambiente confiável',
        DeviceSituation.trusted => 'Ambiente confiável',
        DeviceSituation.street => 'Proteção reforçada',
        DeviceSituation.transit => 'Em movimento',
        DeviceSituation.unknown => 'Aguardando sinais de lugar',
      };

  static DeviceSituation? tryParse(Object? raw) {
    final id = (raw as String?)?.trim().toLowerCase();
    if (id == null || id.isEmpty) return null;
    return switch (id) {
      'home' => DeviceSituation.home,
      'trusted' => DeviceSituation.trusted,
      'street' => DeviceSituation.street,
      'transit' => DeviceSituation.transit,
      'unknown' => DeviceSituation.unknown,
      _ => null,
    };
  }
}
