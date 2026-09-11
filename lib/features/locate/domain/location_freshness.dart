/// Quão “fresca” é a última posição sincronizada.
abstract final class LocationFreshness {
  /// Após isso, avisamos que a posição pode estar desatualizada.
  static const Duration staleAfter = Duration(minutes: 30);

  static bool isStale(DateTime? updatedAt) {
    if (updatedAt == null) return true;
    return DateTime.now().difference(updatedAt) > staleAfter;
  }

  static String? staleMessage(
    DateTime? updatedAt, {
    required bool deviceOnline,
    bool locationReady = true,
  }) {
    if (updatedAt == null) return null;
    if (!isStale(updatedAt)) return null;
    if (!locationReady) {
      return 'Localização desligada — posição da última sincronização.';
    }
    if (!deviceOnline) {
      return 'Aparelho offline — posição da última sincronização.';
    }
    return 'Posição antiga — pode não refletir o local atual do aparelho.';
  }
}
