/// Resumo de uma seção de camadas protegidas sincronizada pelo app mobile.
class ProtectedLayerSummary {
  const ProtectedLayerSummary({
    required this.sectionId,
    required this.title,
    required this.activeCount,
  });

  final String sectionId;
  final String title;
  final int activeCount;

  static const _sectionOrder = [
    'bancos',
    'carteiras',
    'email',
    'contas',
    'contatos',
    'redesSociais',
    'arquivosMidia',
    'navegadores',
    'outros',
  ];

  static List<ProtectedLayerSummary> fromFirestoreList(Object? raw) {
    if (raw is! List) return const [];

    final items = <ProtectedLayerSummary>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final sectionId = map['sectionId'] as String?;
      final title = map['title'] as String?;
      if (sectionId == null || title == null) continue;
      items.add(
        ProtectedLayerSummary(
          sectionId: sectionId,
          title: title,
          activeCount: (map['activeCount'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    items.sort((a, b) {
      final ai = _sectionOrder.indexOf(a.sectionId);
      final bi = _sectionOrder.indexOf(b.sectionId);
      final aRank = ai < 0 ? _sectionOrder.length : ai;
      final bRank = bi < 0 ? _sectionOrder.length : bi;
      if (aRank != bRank) return aRank.compareTo(bRank);
      return a.title.compareTo(b.title);
    });

    return items;
  }

  String get countLabel =>
      activeCount == 1 ? '1 ativo' : '$activeCount ativos';
}

/// Formatação do snapshot de camadas para UI do portal.
abstract final class ProtectedLayerSnapshot {
  static List<ProtectedLayerSummary> activeSections(
    List<ProtectedLayerSummary> layers,
  ) =>
      layers.where((l) => l.activeCount > 0).toList(growable: false);

  static int totalActiveApps(List<ProtectedLayerSummary> layers) =>
      layers.fold(0, (sum, layer) => sum + layer.activeCount);

  /// Ex.: "Bancos 3 · Carteiras 2 · Meus apps 1"
  static String? shortSummary(List<ProtectedLayerSummary> layers) {
    final active = activeSections(layers);
    if (active.isEmpty) return null;
    return active
        .take(3)
        .map((l) => '${l.title} ${l.activeCount}')
        .join(' · ');
  }

  static String summarySubtitle(List<ProtectedLayerSummary> layers) {
    final active = activeSections(layers);
    if (active.isEmpty) {
      return 'Nenhum app ativo nas camadas';
    }
    final apps = totalActiveApps(layers);
    final categories = active.length;
    final appWord = apps == 1 ? 'app' : 'apps';
    final catWord = categories == 1 ? 'categoria' : 'categorias';
    return '$apps $appWord em $categories $catWord';
  }
}
