import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';

void main() {
  test('fromFirestoreList parseia apps instalados por categoria', () {
    final layers = ProtectedLayerSummary.fromFirestoreList([
      {
        'sectionId': 'bancos',
        'title': 'Bancos',
        'activeCount': 2,
        'installedCount': 3,
        'apps': [
          {
            'label': 'Nubank',
            'packageName': 'com.nu.production',
            'protected': true,
          },
          {
            'label': 'Bradesco',
            'packageName': 'com.bradesco',
            'protected': true,
          },
          {
            'label': 'Banco do Brasil',
            'packageName': 'br.com.bb.android',
            'protected': false,
          },
        ],
      },
    ]);

    expect(layers.single.apps.length, 3);
    expect(layers.single.apps[0].label, 'Banco do Brasil');
    expect(layers.single.apps[1].label, 'Bradesco');
    expect(layers.single.apps[2].label, 'Nubank');
    expect(layers.single.apps[2].protected, isTrue);
    expect(layers.single.apps[0].protected, isFalse);
    expect(layers.single.apps[0].packageName, 'br.com.bb.android');
    expect(layers.single.apps[0].canProtectRemotely, isTrue);
    expect(layers.single.apps[2].canProtectRemotely, isFalse);
  });

  test('fromFirestoreList ordena seções e ignora entradas inválidas', () {
    final layers = ProtectedLayerSummary.fromFirestoreList([
      {
        'sectionId': 'outros',
        'title': 'Meus apps',
        'activeCount': 1,
        'installedCount': 1,
      },
      {
        'sectionId': 'bancos',
        'title': 'Bancos',
        'activeCount': 3,
        'installedCount': 3,
      },
      {'title': 'Sem id'},
      {'sectionId': 'carteiras', 'activeCount': 2},
    ]);

    expect(layers.length, 2);
    expect(layers[0].sectionId, 'bancos');
    expect(layers[1].sectionId, 'outros');
    expect(layers[0].activeCount, 3);
    expect(layers[0].installedCount, 3);
  });

  test('DeviceStatus lê protectedLayers do Firestore', () {
    final status = DeviceStatus.fromFirestore('dev-1', {
      'protectedLayers': [
        {
          'sectionId': 'bancos',
          'title': 'Bancos',
          'activeCount': 2,
          'installedCount': 3,
        },
        {'sectionId': 'email', 'title': 'E-mail', 'activeCount': 1},
      ],
    });

    expect(status.hasProtectedLayersSnapshot, isTrue);
    expect(status.protectedLayers.length, 2);
    expect(ProtectedLayerSnapshot.totalActiveApps(status.protectedLayers), 3);
    expect(
      ProtectedLayerSnapshot.shortSummary(status.protectedLayers),
      'Bancos 2 · E-mails 1',
    );
  });

  test('displayTitle usa rótulo curto da home do app', () {
    const layer = ProtectedLayerSummary(
      sectionId: 'carteiras',
      title: 'Carteiras digitais',
      activeCount: 2,
      installedCount: 3,
    );
    expect(layer.displayTitle, 'Carteiras');
    expect(layer.unprotectedCount, 1);
    expect(layer.unprotectedLabel, '1 fora da proteção');
  });

  test('summarySubtitle descreve protegidos e fora da proteção', () {
    final layers = ProtectedLayerSummary.fromFirestoreList([
      {
        'sectionId': 'bancos',
        'title': 'Bancos',
        'activeCount': 2,
        'installedCount': 3,
      },
      {
        'sectionId': 'email',
        'title': 'E-mail',
        'activeCount': 1,
        'installedCount': 1,
      },
    ]);

    expect(
      ProtectedLayerSnapshot.summarySubtitle(layers),
      '3 protegidos · 1 fora da proteção · 2 categorias',
    );
  });

  test('sem installedCount assume todos protegidos (legado)', () {
    final layers = ProtectedLayerSummary.fromFirestoreList([
      {'sectionId': 'bancos', 'title': 'Bancos', 'activeCount': 3},
    ]);

    expect(layers.single.installedCount, 3);
    expect(layers.single.unprotectedCount, 0);
  });
}
