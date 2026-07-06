import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/account/domain/user_plan.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/devices/domain/device_registry.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

GuardianDevice _device({
  required String id,
  String? fingerprint,
  String model = 'Samsung SM-A226BR',
  DateTime? lastSeen,
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
    ),
  );
}

void main() {
  test('dedupe legado: vários UUID v4 do mesmo modelo → um aparelho', () {
    final now = DateTime.now();
    final raw = [
      _device(id: 'a', lastSeen: now.subtract(const Duration(hours: 4))),
      _device(id: 'b', lastSeen: now.subtract(const Duration(hours: 1))),
      _device(id: 'c', lastSeen: now.subtract(const Duration(minutes: 1))),
    ];

    final result = DeviceRegistry.apply(raw, UserPlan.free);

    expect(result.totalDistinct, 1);
    expect(result.visible, hasLength(1));
    expect(result.visible.first.id, 'c');
    expect(result.hiddenCount, 0);
  });

  test('dedupe por fingerprint: mantém o registro mais recente', () {
    final fp = 'fp-uuid-v5-stable';
    final now = DateTime.now();
    final raw = [
      _device(id: 'old-doc', fingerprint: fp, lastSeen: now.subtract(const Duration(days: 1))),
      _device(id: 'stable-doc', fingerprint: fp, lastSeen: now),
    ];

    final result = DeviceRegistry.apply(raw, UserPlan.free);

    expect(result.totalDistinct, 1);
    expect(result.visible.first.id, 'stable-doc');
  });

  test('free limit 1: segundo aparelho físico fica oculto', () {
    final now = DateTime.now();
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

    final result = DeviceRegistry.apply(raw, UserPlan.free);

    expect(result.totalDistinct, 2);
    expect(result.visible, hasLength(1));
    expect(result.visible.first.id, 'phone-a');
    expect(result.hiddenCount, 1);
    expect(result.isOverLimit, isTrue);
  });

  test('pro plan: exibe até deviceLimit', () {
    final now = DateTime.now();
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
    );

    expect(result.visible, hasLength(3));
    expect(result.hiddenCount, 0);
  });
}
