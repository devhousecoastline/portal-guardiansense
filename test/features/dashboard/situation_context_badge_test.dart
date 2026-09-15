import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/dashboard/domain/device_situation.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/situation_context_badge.dart';

DeviceStatus _status({DeviceSituation? situation}) {
  return DeviceStatus(
    deviceId: 'dev-1',
    modelLabel: 'Pixel',
    platform: 'android',
    appVersion: '1.0',
    lastSeen: DateTime.now(),
    storedProtectionIndex: 90,
    runtimeActive: true,
    oysterClosed: false,
    batteryLevel: null,
    lastAlertAt: null,
    lastAlertSummary: null,
    lastEventAt: null,
    lastEventSummary: null,
    location: null,
    fingerprint: 'fp',
    protectionSetupItems: const [],
    protectedLayers: const [],
    situation: situation,
    situationConfidence: situation == null ? null : 0.87,
  );
}

void main() {
  testWidgets('não renderiza sem situation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SituationContextBadge(status: _status()),
        ),
      ),
    );
    expect(find.textContaining('Casa'), findsNothing);
  });

  testWidgets('no cabeçalho compacto mostra só o label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SituationContextBadge(
            status: _status(situation: DeviceSituation.home),
            compact: true,
          ),
        ),
      ),
    );
    expect(find.text('Casa'), findsOneWidget);
    expect(find.textContaining('Ambiente confiável'), findsNothing);
    expect(find.textContaining('87%'), findsNothing);
  });

  testWidgets('no desktop mostra label e hint na mesma linha', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SituationContextBadge(
            status: _status(situation: DeviceSituation.home),
          ),
        ),
      ),
    );
    expect(find.textContaining('Casa'), findsOneWidget);
    expect(find.textContaining('Ambiente confiável'), findsOneWidget);
    expect(find.textContaining('87%'), findsNothing);
  });
}
