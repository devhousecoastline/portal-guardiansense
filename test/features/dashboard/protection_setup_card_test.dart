import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/core/theme/app_theme.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_setup_card.dart';

const _items = [
  ProtectionSetupItem(id: 'notifications', label: 'Notificações', done: true),
  ProtectionSetupItem(id: 'accessibility', label: 'Acessibilidade', done: true),
  ProtectionSetupItem(id: 'battery', label: 'Bateria', done: true),
  ProtectionSetupItem(id: 'protected_layers', label: 'Camadas', done: true),
  ProtectionSetupItem(id: 'recovery', label: 'Recuperação', done: true),
];

DeviceStatus _status({bool online = true}) {
  return DeviceStatus(
    deviceId: 'd1',
    modelLabel: 'Samsung SM-A226BR',
    platform: 'android',
    appVersion: '1.0.0',
    lastSeen: online ? DateTime.now() : DateTime(2020),
    storedProtectionIndex: 100,
    runtimeActive: true,
    oysterClosed: false,
    batteryLevel: null,
    lastAlertAt: null,
    lastAlertSummary: null,
    lastEventAt: null,
    lastEventSummary: null,
    location: null,
    fingerprint: null,
    protectionSetupItems: _items,
    protectedLayers: const [],
  );
}

Future<void> _pump(WidgetTester tester, {bool online = true}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProtectionSetupCard(status: _status(online: online)),
        ),
      ),
    ),
  );
}

List<Color?> _timelineIconColors(WidgetTester tester) {
  final timelineIcons = <IconData>[
    Icons.notifications_outlined,
    Icons.accessibility_new_rounded,
    Icons.battery_charging_full_rounded,
    Icons.layers_outlined,
    Icons.fingerprint,
  ];

  return tester
      .widgetList<Icon>(find.byType(Icon))
      .where((icon) => timelineIcons.contains(icon.icon))
      .map((icon) => icon.color)
      .toList();
}

void main() {
  testWidgets('cada requisito configurado usa a própria cor', (tester) async {
    await _pump(tester);

    final colors = _timelineIconColors(tester);

    expect(colors, hasLength(_items.length));
    expect(colors.toSet(), hasLength(_items.length));
  });

  testWidgets('requisitos ficam neutros com o aparelho offline', (
    tester,
  ) async {
    await _pump(tester, online: false);

    final colors = _timelineIconColors(tester);

    expect(colors, hasLength(_items.length));
    expect(colors.toSet(), hasLength(1));
  });
}
