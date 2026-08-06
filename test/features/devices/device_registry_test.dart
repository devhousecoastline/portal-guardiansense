import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/account/domain/user_plan.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/devices/domain/device_registry.dart';
import 'package:guardian_portal/features/devices/domain/device_switches.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

GuardianDevice _device({
  required String id,
  String? fingerprint,
  String model = 'Samsung SM-A226BR',
  DateTime? lastSeen,
  DeviceBindingStatus bindingStatus = DeviceBindingStatus.active,
  DateTime? releasedAt,
}) {
  return GuardianDevice(
    id: id,
    status: DeviceStatus(
      deviceId: id,
      modelLabel: model,
      platform: 'android',
      appVersion: '1.0.0',
      lastSeen: lastSeen,
      storedProtectionIndex: 100,
      runtimeActive: true,
      oysterClosed: false,
      batteryLevel: null,
      lastAlertAt: null,
      lastAlertSummary: null,
      lastEventAt: null,
      lastEventSummary: null,
      location: null,
      fingerprint: fingerprint,
      protectionSetupItems: const [],
      protectedLayers: const [],
      bindingStatus: bindingStatus,
      releasedAt: releasedAt,
    ),
  );
}

void main() {
  final now = DateTime.utc(2026, 8, 6);
  final switches = DeviceSwitches(
    periodStart: now,
    periodEnd: now.add(const Duration(days: 365)),
    used: 1,
    included: 2,
    extraPurchased: 0,
  );

  test('dedupe legado: vários UUID v4 do mesmo modelo → um aparelho', () {
    final raw = [
      _device(id: 'a', lastSeen: now.subtract(const Duration(hours: 4))),
      _device(id: 'b', lastSeen: now.subtract(const Duration(hours: 1))),
      _device(id: 'c', lastSeen: now.subtract(const Duration(minutes: 1))),
    ];

    final result = DeviceRegistry.apply(raw, UserPlan.free, switches: switches);

    expect(result.totalDistinct, 1);
    expect(result.visible, hasLength(1));
    expect(result.visible.first.id, 'c');
    expect(result.hiddenCount, 0);
    expect(result.released, isEmpty);
    expect(result.switches.used, 1);
  });

  test('dedupe por fingerprint: mantém o registro mais recente', () {
    final fp = 'fp-uuid-v5-stable';
    final raw = [
      _device(
        id: 'old-doc',
        fingerprint: fp,
        lastSeen: now.subtract(const Duration(days: 1)),
      ),
      _device(id: 'stable-doc', fingerprint: fp, lastSeen: now),
    ];

    final result = DeviceRegistry.apply(raw, UserPlan.free, switches: switches);

    expect(result.totalDistinct, 1);
    expect(result.visible.first.id, 'stable-doc');
  });

  test('free limit 1: segundo aparelho físico fica oculto', () {
    final raw = [
      _device(
        id: 'phone-a',
        fingerprint: 'fp-a',
        model: 'Samsung A',
        lastSeen: now,
      ),
      _device(
        id: 'phone-b',
        fingerprint: 'fp-b',
        model: 'Motorola G',
        lastSeen: now.subtract(const Duration(minutes: 5)),
      ),
    ];

    final result = DeviceRegistry.apply(raw, UserPlan.free, switches: switches);

    expect(result.totalDistinct, 2);
    expect(result.visible, hasLength(1));
    expect(result.visible.first.id, 'phone-a');
    expect(result.hiddenCount, 1);
    expect(result.isOverLimit, isTrue);
  });

  test('pro plan: exibe até deviceLimit', () {
    final raw = List.generate(
      3,
      (i) => _device(
        id: 'd$i',
        fingerprint: 'fp-$i',
        model: 'Phone $i',
        lastSeen: now.subtract(Duration(minutes: i)),
      ),
    );

    final result = DeviceRegistry.apply(
      raw,
      const UserPlan(plan: 'pro', deviceLimit: 5),
      switches: switches,
    );

    expect(result.visible, hasLength(3));
    expect(result.hiddenCount, 0);
  });

  test('released ficam no histórico e não no ativo', () {
    final raw = [
      _device(
        id: 'active',
        fingerprint: 'fp-a',
        model: 'Atual',
        lastSeen: now,
      ),
      _device(
        id: 'old',
        fingerprint: 'fp-b',
        model: 'Anterior',
        lastSeen: now.subtract(const Duration(days: 10)),
        bindingStatus: DeviceBindingStatus.released,
        releasedAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    final result = DeviceRegistry.apply(
      raw,
      UserPlan.free,
      boundDeviceId: 'active',
      switches: switches,
    );

    expect(result.visible.map((d) => d.id), ['active']);
    expect(result.released.map((d) => d.id), ['old']);
    expect(result.primary?.id, 'active');
  });

  test('boundDeviceId sobe para o topo dos ativos', () {
    final raw = [
      _device(
        id: 'newer',
        fingerprint: 'fp-new',
        model: 'Novo',
        lastSeen: now,
      ),
      _device(
        id: 'bound',
        fingerprint: 'fp-bound',
        model: 'Bound',
        lastSeen: now.subtract(const Duration(hours: 1)),
      ),
    ];

    final result = DeviceRegistry.apply(
      raw,
      const UserPlan(plan: 'pro', deviceLimit: 5),
      boundDeviceId: 'bound',
      switches: switches,
    );

    expect(result.visible.first.id, 'bound');
  });
}
