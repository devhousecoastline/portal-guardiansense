import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/devices/domain/device_switches.dart';

void main() {
  final now = DateTime.utc(2026, 8, 6);

  test('fromUserDoc lê used/included e respeita trial', () {
    final switches = DeviceSwitches.fromUserDoc(
      {
        'subscription': {'status': 'trial'},
        'deviceSwitches': {
          'periodStart': now,
          'periodEnd': now.add(const Duration(days: 365)),
          'used': 1,
          'included': 1,
          'extraPurchased': 0,
        },
      },
      now: now,
    );

    expect(switches.used, 1);
    expect(switches.allowance, 1);
    expect(switches.canSwitch, isFalse);
    expect(switches.remaining, 0);
  });

  test('período vencido zera used no resolve', () {
    final switches = DeviceSwitches.resolve(
      {
        'periodStart': now.subtract(const Duration(days: 400)),
        'periodEnd': now.subtract(const Duration(days: 35)),
        'used': 2,
        'included': 2,
        'extraPurchased': 1,
      },
      now: now,
      defaultIncluded: 2,
    );

    expect(switches.used, 0);
    expect(switches.extraPurchased, 0);
    expect(switches.included, 2);
    expect(switches.canSwitch, isTrue);
  });
}
