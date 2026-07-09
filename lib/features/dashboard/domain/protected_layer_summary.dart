import 'package:flutter/material.dart';

/// App instalado em uma camada protegida — sincronizado pelo app mobile.
class ProtectedLayerAppSummary {
  const ProtectedLayerAppSummary({
    required this.label,
    required this.protected,
    this.packageName,
  });

  final String label;
  final bool protected;
  final String? packageName;

  bool get canProtectRemotely =>
      !protected && packageName != null && packageName!.isNotEmpty;

  static List<ProtectedLayerAppSummary> fromFirestoreList(Object? raw) {
    if (raw is! List) return const [];

    final items = <ProtectedLayerAppSummary>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final label = map['label'] as String?;
      if (label == null || label.isEmpty) continue;
      final packageName = map['packageName'] as String?;
      items.add(
        ProtectedLayerAppSummary(
          label: label,
          protected: map['protected'] as bool? ?? false,
          packageName: packageName?.isNotEmpty == true ? packageName : null,
        ),
      );
    }

    items.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return items;
  }
}

/// Resumo de uma seção de camadas protegidas sincronizada pelo app mobile.
class ProtectedLayerSummary {
  const ProtectedLayerSummary({
    required this.sectionId,
    required this.title,
    required this.activeCount,
    required this.installedCount,
    this.apps = const [],
  });

  final String sectionId;
  final String title;
  final int activeCount;
  final int installedCount;
  final List<ProtectedLayerAppSummary> apps;

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
      final active = (map['activeCount'] as num?)?.toInt() ?? 0;
      final installed = (map['installedCount'] as num?)?.toInt() ?? active;
      items.add(
        ProtectedLayerSummary(
          sectionId: sectionId,
          title: title,
          activeCount: active,
          installedCount: installed < active ? active : installed,
          apps: ProtectedLayerAppSummary.fromFirestoreList(map['apps']),
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

  int get unprotectedCount =>
      (installedCount - activeCount).clamp(0, installedCount);

  bool get isFullyProtected =>
      installedCount > 0 && activeCount >= installedCount;

  bool get hasInstalledApps => installedCount > 0;

  String get protectedLabel => activeCount == 1
      ? '1 protegido'
      : '$activeCount protegidos';

  String get unprotectedLabel => unprotectedCount == 1
      ? '1 fora da proteção'
      : '$unprotectedCount fora da proteção';

  IconData get icon => ProtectedLayerCatalog.iconFor(sectionId);

  /// Título curto para UI — igual aos cards da home do app.
  String get displayTitle =>
      ProtectedLayerCatalog.shortTitleFor(sectionId, title);
}

/// Metadados visuais das camadas — alinhado ao app mobile.
abstract final class ProtectedLayerCatalog {
  static String shortTitleFor(String sectionId, String fallback) =>
      switch (sectionId) {
        'bancos' => 'Bancos',
        'carteiras' => 'Carteiras',
        'email' => 'E-mails',
        'contas' => 'Contas',
        'contatos' => 'Contatos',
        'redesSociais' => 'Redes sociais',
        'arquivosMidia' => 'Arquivos e mídia',
        'navegadores' => 'Navegadores',
        'outros' => 'Meus apps',
        _ => fallback,
      };

  static IconData iconFor(String sectionId) => switch (sectionId) {
        'bancos' => Icons.account_balance,
        'carteiras' => Icons.credit_card,
        'email' => Icons.mail_outline,
        'contas' => Icons.person_outline,
        'contatos' => Icons.contact_phone_outlined,
        'redesSociais' => Icons.verified_user,
        'arquivosMidia' => Icons.perm_media_outlined,
        'navegadores' => Icons.language_outlined,
        'outros' => Icons.apps_outlined,
        _ => Icons.layers_outlined,
      };
}

/// Formatação do snapshot de camadas para UI do portal.
abstract final class ProtectedLayerSnapshot {
  /// Categorias com apps instalados no aparelho.
  static List<ProtectedLayerSummary> visibleSections(
    List<ProtectedLayerSummary> layers,
  ) =>
      layers.where((l) => l.hasInstalledApps).toList(growable: false);

  static List<ProtectedLayerSummary> activeSections(
    List<ProtectedLayerSummary> layers,
  ) =>
      layers.where((l) => l.activeCount > 0).toList(growable: false);

  static int totalActiveApps(List<ProtectedLayerSummary> layers) =>
      layers.fold(0, (sum, layer) => sum + layer.activeCount);

  static int totalUnprotectedApps(List<ProtectedLayerSummary> layers) =>
      layers.fold(0, (sum, layer) => sum + layer.unprotectedCount);

  /// Ex.: "Bancos 3 · Carteiras 2 · Meus apps 1"
  static String? shortSummary(List<ProtectedLayerSummary> layers) {
    final visible = visibleSections(layers);
    if (visible.isEmpty) return null;
    return visible
        .take(3)
        .map((l) => '${l.displayTitle} ${l.activeCount}')
        .join(' · ');
  }

  static String summarySubtitle(List<ProtectedLayerSummary> layers) {
    final visible = visibleSections(layers);
    if (visible.isEmpty) {
      return 'Nenhum app instalado nas camadas';
    }
    final protected = totalActiveApps(layers);
    final outside = totalUnprotectedApps(layers);
    final categories = visible.length;
    final catWord = categories == 1 ? 'categoria' : 'categorias';

    if (outside == 0) {
      final appWord = protected == 1 ? 'app' : 'apps';
      return '$protected $appWord protegidos em $categories $catWord';
    }

    final protWord = protected == 1 ? 'protegido' : 'protegidos';
    final outLabel = outside == 1
        ? '1 fora da proteção'
        : '$outside fora da proteção';
    return '$protected $protWord · $outLabel · $categories $catWord';
  }
}
