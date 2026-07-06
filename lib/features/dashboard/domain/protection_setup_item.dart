/// Requisito de configuração sincronizado pelo app mobile.
class ProtectionSetupItem {
  const ProtectionSetupItem({
    required this.id,
    required this.label,
    required this.done,
  });

  final String id;
  final String label;
  final bool done;

  static List<ProtectionSetupItem> fromFirestoreList(Object? raw) {
    if (raw is! List) return const [];

    final items = <ProtectionSetupItem>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final id = map['id'] as String?;
      final label = map['label'] as String?;
      if (id == null || label == null) continue;
      items.add(
        ProtectionSetupItem(
          id: id,
          label: label,
          done: map['done'] as bool? ?? false,
        ),
      );
    }
    return items;
  }
}
