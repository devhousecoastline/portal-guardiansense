import 'package:guardian_portal/features/account/domain/user_plan.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

/// Resultado da lista de dispositivos após dedupe e limite do plano.
class DeviceListSnapshot {
  const DeviceListSnapshot({
    required this.visible,
    required this.totalDistinct,
    required this.hiddenCount,
    required this.plan,
  });

  final List<GuardianDevice> visible;
  final int totalDistinct;
  final int hiddenCount;
  final UserPlan plan;

  bool get isOverLimit => hiddenCount > 0;
}

/// Agrupa por aparelho físico e aplica [UserPlan.deviceLimit].
abstract final class DeviceRegistry {
  static DeviceListSnapshot apply(
    List<GuardianDevice> raw,
    UserPlan plan,
  ) {
    final deduped = _dedupeByPhysicalDevice(raw);
    final visible = deduped.take(plan.deviceLimit).toList();
    final hidden = deduped.length - visible.length;

    return DeviceListSnapshot(
      visible: visible,
      totalDistinct: deduped.length,
      hiddenCount: hidden.clamp(0, deduped.length),
      plan: plan,
    );
  }

  /// Um aparelho físico = mesmo [DeviceStatus.fingerprint], ou legado sem
  /// fingerprint agrupado por plataforma + modelo (limpa órfãos de UUID v4).
  static List<GuardianDevice> _dedupeByPhysicalDevice(
    List<GuardianDevice> devices,
  ) {
    final sorted = [...devices]
      ..sort((a, b) => _compareLastSeen(b.status.lastSeen, a.status.lastSeen));

    final winners = <String, GuardianDevice>{};
    for (final device in sorted) {
      final key = _groupKey(device);
      winners.putIfAbsent(key, () => device);
    }

    final fingerprintModels = winners.entries
        .where((e) => e.key.startsWith('fp:'))
        .map((e) => _modelKey(e.value))
        .toSet();

    final deduped = winners.entries
        .where((e) {
          if (!e.key.startsWith('legacy:')) return true;
          final modelKey = e.key.substring('legacy:'.length);
          return !fingerprintModels.contains(modelKey);
        })
        .map((e) => e.value)
        .toList()
      ..sort((a, b) => _compareLastSeen(b.status.lastSeen, a.status.lastSeen));

    return deduped;
  }

  static String _groupKey(GuardianDevice device) {
    final fp = device.status.fingerprint;
    if (fp != null && fp.isNotEmpty) return 'fp:$fp';
    return 'legacy:${_modelKey(device)}';
  }

  static String _modelKey(GuardianDevice device) =>
      '${device.status.platform}|${device.status.modelLabel}';

  static int _compareLastSeen(DateTime? a, DateTime? b) {
    final ta = a ?? DateTime.fromMillisecondsSinceEpoch(0);
    final tb = b ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ta.compareTo(tb);
  }
}
