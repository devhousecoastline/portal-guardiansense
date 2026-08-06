import 'package:guardian_portal/features/account/domain/user_plan.dart';
import 'package:guardian_portal/features/devices/domain/device_switches.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

/// Resultado da lista de dispositivos após dedupe, vínculo e histórico.
class DeviceListSnapshot {
  const DeviceListSnapshot({
    required this.visible,
    required this.released,
    required this.totalDistinct,
    required this.hiddenCount,
    required this.plan,
    required this.switches,
    this.boundDeviceId,
  });

  /// Aparelhos **ativos** visíveis no portal (após dedupe + limite do plano).
  final List<GuardianDevice> visible;

  /// Histórico de aparelhos desvinculados (`status: released`).
  final List<GuardianDevice> released;

  final int totalDistinct;
  final int hiddenCount;
  final UserPlan plan;
  final DeviceSwitches switches;
  final String? boundDeviceId;

  bool get isOverLimit => hiddenCount > 0;

  GuardianDevice? get primary =>
      visible.isEmpty ? null : visible.first;

  bool get hasActive => visible.isNotEmpty;

  bool get hasReleased => released.isNotEmpty;
}

/// Agrupa por aparelho físico, separa released e aplica [UserPlan.deviceLimit].
abstract final class DeviceRegistry {
  static DeviceListSnapshot apply(
    List<GuardianDevice> raw,
    UserPlan plan, {
    String? boundDeviceId,
    DeviceSwitches? switches,
  }) {
    final now = DateTime.now().toUtc();
    final resolvedSwitches = switches ??
        DeviceSwitches.fresh(
          now: now,
          included: DeviceSwitches.includedForAnnual,
        );

    final released = raw.where((d) => d.status.isReleased).toList()
      ..sort((a, b) => _compareReleased(b, a));

    final activeRaw = raw.where((d) => !d.status.isReleased).toList();
    final deduped = _dedupeByPhysicalDevice(activeRaw);
    final ordered = _preferBound(deduped, boundDeviceId);
    final visible = ordered.take(plan.deviceLimit).toList();
    final hidden = ordered.length - visible.length;

    return DeviceListSnapshot(
      visible: visible,
      released: released,
      totalDistinct: deduped.length,
      hiddenCount: hidden.clamp(0, ordered.length),
      plan: plan,
      switches: resolvedSwitches,
      boundDeviceId: boundDeviceId,
    );
  }

  static List<GuardianDevice> _preferBound(
    List<GuardianDevice> devices,
    String? boundDeviceId,
  ) {
    final bound = boundDeviceId?.trim();
    if (bound == null || bound.isEmpty) return devices;

    final index = devices.indexWhere((d) => d.id == bound);
    if (index <= 0) return devices;

    final copy = [...devices];
    final match = copy.removeAt(index);
    return [match, ...copy];
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

  static int _compareReleased(GuardianDevice a, GuardianDevice b) {
    final byReleased = _compareLastSeen(
      a.status.releasedAt,
      b.status.releasedAt,
    );
    if (byReleased != 0) return byReleased;
    return _compareLastSeen(a.status.lastSeen, b.status.lastSeen);
  }
}
