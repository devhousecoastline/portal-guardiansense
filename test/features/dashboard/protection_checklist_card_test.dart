import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/core/layout/dashboard_layout.dart';
import 'package:guardian_portal/core/theme/app_theme.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_checklist_card.dart';

DeviceStatus _status({bool unprotectedApps = true}) {
  return DeviceStatus(
    deviceId: 'd1',
    modelLabel: 'Samsung SM-A226BR',
    platform: 'android',
    appVersion: '1.0.0',
    lastSeen: DateTime.now(),
    storedProtectionIndex: 100,
    runtimeActive: true,
    oysterClosed: false,
    batteryLevel: null,
    lastAlertAt: null,
    lastAlertSummary: null,
    lastEventAt: DateTime.now().subtract(const Duration(minutes: 3)),
    lastEventSummary: 'app bloqueado',
    location: null,
    fingerprint: null,
    protectionSetupItems: const [
      ProtectionSetupItem(id: 'notif', label: 'Notificações', done: true),
      ProtectionSetupItem(id: 'acess', label: 'Acessibilidade', done: true),
    ],
    protectedLayers: ProtectedLayerSummary.fromFirestoreList([
      {
        'sectionId': 'bancos',
        'title': 'Bancos',
        'activeCount': unprotectedApps ? 1 : 2,
        'installedCount': 2,
        'apps': [
          {
            'label': 'Bradesco',
            'packageName': 'com.bradesco',
            'protected': !unprotectedApps,
          },
          {
            'label': 'Nubank',
            'packageName': 'com.nu.production',
            'protected': true,
          },
        ],
      },
    ]),
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required double cardWidth,
  double? cardHeight,
  bool notebook = true,
  bool unprotectedApps = true,
}) async {
  final card = ProtectionChecklistCard(
    status: _status(unprotectedApps: unprotectedApps),
    compact: notebook,
    pairGrid: notebook,
    expandVertically: notebook,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: cardWidth, height: cardHeight, child: card),
        ),
      ),
    ),
  );
}

double _tileHeight(WidgetTester tester, String question) {
  return tester
      .getSize(
        find.ancestor(of: find.text(question), matching: find.byType(InkWell)),
      )
      .height;
}

void main() {
  testWidgets(
    'apps fora da proteção e último evento ficam lado a lado no notebook',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 576);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pumpCard(
        tester,
        cardWidth: 361,
        cardHeight: DashboardLayoutSpec.notebookCellHeight(576),
      );

      final apps = tester.getTopLeft(find.text('Apps fora da proteção'));
      final event = tester.getTopLeft(find.text('Último evento de segurança'));

      expect(apps.dy, event.dy, reason: 'blocos devem ficar lado a lado');
      expect(apps.dx, lessThan(event.dx));
    },
  );

  testWidgets('rodapé empilha em coluna estreita e mantém o chevron', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpCard(tester, cardWidth: 388, notebook: false);

    final apps = tester.getTopLeft(find.text('Apps fora da proteção'));
    final event = tester.getTopLeft(find.text('Último evento de segurança'));

    expect(apps.dy, lessThan(event.dy));
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    expect(find.text('Ajustar em Configurações'), findsNothing);
    expect(find.text('Ver detalhes'), findsNothing);
  });

  testWidgets('bloco sozinho mantém a altura do par lado a lado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 576);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const question = 'Último evento de segurança';
    final cardHeight = DashboardLayoutSpec.notebookCellHeight(576);

    await _pumpCard(tester, cardWidth: 361, cardHeight: cardHeight);
    final paired = _tileHeight(tester, question);

    await _pumpCard(
      tester,
      cardWidth: 361,
      cardHeight: cardHeight,
      unprotectedApps: false,
    );
    final alone = _tileHeight(tester, question);

    expect(find.text('Apps fora da proteção'), findsNothing);
    expect(alone, paired);
  });
}
