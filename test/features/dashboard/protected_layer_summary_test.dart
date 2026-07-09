import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';

void main() {
  test('fromFirestoreList ordena seções e ignora entradas inválidas', () {
    final layers = ProtectedLayerSummary.fromFirestoreList([
      {'sectionId': 'outros', 'title': 'Meus apps', 'activeCount': 1},
      {'sectionId': 'bancos', 'title': 'Bancos', 'activeCount': 3},
      {'title': 'Sem id'},
      {'sectionId': 'carteiras', 'activeCount': 2},
    ]);

    expect(layers.length, 2);
    expect(layers[0].sectionId, 'bancos');
    expect(layers[1].sectionId, 'outros');
    expect(layers[0].activeCount, 3);
  });

  test('DeviceStatus lê protectedLayers do Firestore', () {
    final status = DeviceStatus.fromFirestore('dev-1', {
      'protectedLayers': [
        {'sectionId': 'bancos', 'title': 'Bancos', 'activeCount': 2},
        {'sectionId': 'email', 'title': 'E-mail', 'activeCount': 1},
      ],
    });

    expect(status.hasProtectedLayersSnapshot, isTrue);
    expect(status.protectedLayers.length, 2);
    expect(ProtectedLayerSnapshot.totalActiveApps(status.protectedLayers), 3);
    expect(
      ProtectedLayerSnapshot.shortSummary(status.protectedLayers),
      'Bancos 2 · E-mail 1',
    );
  });

  test('summarySubtitle descreve totais', () {
    final layers = ProtectedLayerSummary.fromFirestoreList([
      {'sectionId': 'bancos', 'title': 'Bancos', 'activeCount': 2},
      {'sectionId': 'carteiras', 'title': 'Carteiras', 'activeCount': 0},
      {'sectionId': 'email', 'title': 'E-mail', 'activeCount': 1},
    ]);

    expect(
      ProtectedLayerSnapshot.summarySubtitle(layers),
      '3 apps em 2 categorias',
    );
  });
}
