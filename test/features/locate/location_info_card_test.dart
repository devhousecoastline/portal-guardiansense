import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/core/theme/app_theme.dart';
import 'package:guardian_portal/features/dashboard/domain/device_location.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';
import 'package:guardian_portal/features/locate/presentation/widgets/location_info_card.dart';

DeviceStatus _status({
  DeviceLocation? location,
  bool online = true,
  bool? locationDone,
}) {
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
    location: location,
    fingerprint: null,
    protectionSetupItems: locationDone == null
        ? const []
        : [
            ProtectionSetupItem(
              id: 'location',
              label: 'Localização',
              done: locationDone,
            ),
          ],
    protectedLayers: const [],
  );
}

Future<void> _pump(
  WidgetTester tester,
  DeviceStatus status, {
  DeviceLocation? focusLocation,
  String? focusCaption,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: LocationInfoCard(
            status: status,
            focusLocation: focusLocation,
            focusCaption: focusCaption,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('posição recente aparece como atual', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      _status(
        location: DeviceLocation(
          lat: -23.55052,
          lng: -46.63331,
          accuracyM: 25,
          updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
          source: 'foreground',
        ),
      ),
    );

    expect(
      find.textContaining('POSIÇÃO ATUAL', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.textContaining('-23.55052, -46.63331'), findsOneWidget);
  });

  testWidgets('posição vencida vira alerta de posição antiga', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      _status(
        location: DeviceLocation(
          lat: -23.55052,
          lng: -46.63331,
          accuracyM: 25,
          updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ),
    );

    expect(
      find.textContaining('POSIÇÃO ANTIGA', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('pode não refletir'), findsOneWidget);
  });

  testWidgets('card largo distribui os blocos em colunas', (tester) async {
    tester.view.physicalSize = const Size(1280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      _status(
        location: DeviceLocation(
          lat: -23.55052,
          lng: -46.63331,
          accuracyM: 25,
          updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      ),
    );

    final model = tester.getTopLeft(find.text('Samsung SM-A226BR'));
    final address = tester.getTopLeft(
      find.textContaining('Endereço aproximado'),
    );
    final coords = tester.getTopLeft(
      find.textContaining('-23.55052, -46.63331'),
    );

    expect(model.dx, lessThan(address.dx));
    expect(address.dx, lessThan(coords.dx));
    expect(find.text('ONLINE'), findsOneWidget);
  });

  testWidgets('sem posição esconde coordenadas', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, _status());

    expect(
      find.textContaining('SEM POSIÇÃO', findRichText: true),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.copy_outlined), findsNothing);
    expect(
      find.textContaining('Aguardando a primeira posição'),
      findsOneWidget,
    );
  });

  testWidgets('GPS off no checklist marca OFFLINE mesmo com lastSeen fresco',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      _status(
        locationDone: false,
        location: DeviceLocation(
          lat: -23.55052,
          lng: -46.63331,
          accuracyM: 25,
          updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      ),
    );

    expect(find.text('OFFLINE'), findsOneWidget);
    expect(
      find.textContaining('GPS off', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('focusLocation mostra LOCAL DO HISTÓRICO', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      _status(
        location: DeviceLocation(
          lat: -23.55,
          lng: -46.63,
          accuracyM: 20,
          updatedAt: DateTime.now(),
        ),
      ),
      focusLocation: DeviceLocation(
        lat: -29.76771,
        lng: -50.02235,
        accuracyM: 16,
        updatedAt: DateTime(2026, 9, 11, 16, 51),
        source: 'background',
      ),
      focusCaption: '16:51–17:29 · mesmo local · ~37 min',
    );

    expect(
      find.textContaining('LOCAL DO HISTÓRICO', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('16:51–17:29'), findsOneWidget);
    expect(find.textContaining('-29.76771, -50.02235'), findsOneWidget);
  });
}
