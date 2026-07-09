import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';

void main() {
  test('evento recente usa resumo curto', () {
    final status = DeviceStatus(
      deviceId: 'd1',
      modelLabel: 'Samsung',
      platform: 'android',
      appVersion: '1',
      lastSeen: DateTime.now(),
      storedProtectionIndex: 100,
      runtimeActive: true,
      oysterClosed: false,
      batteryLevel: null,
      lastAlertAt: null,
      lastAlertSummary: null,
      lastEventAt: DateTime.now().subtract(const Duration(minutes: 15)),
      lastEventSummary: 'ostra reaberta · usuário confirmou segurança',
      location: null,
      fingerprint: null,
      protectionSetupItems: const [],
      protectedLayers: const [],
    );

    final entries = ProtectionSnapshot.checklist(status);
    final event = entries.firstWhere(
      (e) => e.question.startsWith('Último evento'),
    );

    expect(event.answer, contains('Ostra reaberta'));
    expect(event.answer, isNot(contains('usuário confirmou')));
  });

  test('ostra reaberta antiga com aparelho protegido fica muted', () {
    final status = DeviceStatus(
      deviceId: 'd1',
      modelLabel: 'Samsung',
      platform: 'android',
      appVersion: '1',
      lastSeen: DateTime.now(),
      storedProtectionIndex: 100,
      runtimeActive: true,
      oysterClosed: false,
      batteryLevel: null,
      lastAlertAt: null,
      lastAlertSummary: null,
      lastEventAt: DateTime.now().subtract(const Duration(minutes: 23)),
      lastEventSummary: 'ostra reaberta',
      location: null,
      fingerprint: null,
      protectionSetupItems: const [],
      protectedLayers: const [],
    );

    final entries = ProtectionSnapshot.checklist(status);
    final event = entries.firstWhere(
      (e) => e.question.startsWith('Último evento'),
    );

    expect(event.signal, ChecklistSignal.muted);
  });

  test('app bloqueado recente permanece em alerta', () {
    final status = DeviceStatus(
      deviceId: 'd1',
      modelLabel: 'Samsung',
      platform: 'android',
      appVersion: '1',
      lastSeen: DateTime.now(),
      storedProtectionIndex: 100,
      runtimeActive: true,
      oysterClosed: false,
      batteryLevel: null,
      lastAlertAt: null,
      lastAlertSummary: null,
      lastEventAt: DateTime.now().subtract(const Duration(minutes: 5)),
      lastEventSummary: 'app bloqueado',
      location: null,
      fingerprint: null,
      protectionSetupItems: const [],
      protectedLayers: const [],
    );

    final entries = ProtectionSnapshot.checklist(status);
    final event = entries.firstWhere(
      (e) => e.question.startsWith('Último evento'),
    );

    expect(event.signal, ChecklistSignal.alert);
  });

  test('lista apps fora da proteção quando houver', () {
    final status = DeviceStatus(
      deviceId: 'd1',
      modelLabel: 'Samsung',
      platform: 'android',
      appVersion: '1',
      lastSeen: DateTime.now(),
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
      protectionSetupItems: const [],
      protectedLayers: ProtectedLayerSummary.fromFirestoreList([
        {
          'sectionId': 'bancos',
          'title': 'Bancos',
          'activeCount': 2,
          'installedCount': 3,
          'apps': [
            {'label': 'Bradesco', 'packageName': 'com.bradesco', 'protected': false},
            {'label': 'Nubank', 'packageName': 'com.nu.production', 'protected': true},
          ],
        },
        {
          'sectionId': 'carteiras',
          'title': 'Carteiras',
          'activeCount': 1,
          'installedCount': 2,
          'apps': [
            {'label': 'PagBank', 'packageName': 'br.com.uol.ps.myaccount', 'protected': false},
          ],
        },
      ]),
    );

    final entries = ProtectionSnapshot.checklist(status);
    final unprotected = entries.where(
      (e) => e.question.startsWith('Apps fora'),
    );

    expect(unprotected, hasLength(1));
    expect(unprotected.single.answer, 'Existem 2 apps fora da proteção');
    expect(unprotected.single.signal, ChecklistSignal.warn);
  });

  test('oculta apps fora da proteção quando todos estão protegidos', () {
    final status = DeviceStatus(
      deviceId: 'd1',
      modelLabel: 'Samsung',
      platform: 'android',
      appVersion: '1',
      lastSeen: DateTime.now(),
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
      protectionSetupItems: const [],
      protectedLayers: ProtectedLayerSummary.fromFirestoreList([
        {
          'sectionId': 'bancos',
          'title': 'Bancos',
          'activeCount': 2,
          'installedCount': 2,
          'apps': [
            {'label': 'Nubank', 'protected': true},
            {'label': 'Bradesco', 'protected': true},
          ],
        },
      ]),
    );

    final entries = ProtectionSnapshot.checklist(status);
    expect(
      entries.any((e) => e.question.startsWith('Apps fora')),
      isFalse,
    );
  });

  test('usa singular para um app fora da proteção', () {
    final status = DeviceStatus(
      deviceId: 'd1',
      modelLabel: 'Samsung',
      platform: 'android',
      appVersion: '1',
      lastSeen: DateTime.now(),
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
      protectionSetupItems: const [],
      protectedLayers: ProtectedLayerSummary.fromFirestoreList([
        {
          'sectionId': 'bancos',
          'title': 'Bancos',
          'activeCount': 1,
          'installedCount': 2,
          'apps': [
            {'label': 'Bradesco', 'protected': false},
            {'label': 'Nubank', 'protected': true},
          ],
        },
      ]),
    );

    final entry = ProtectionSnapshot.checklist(status).singleWhere(
      (e) => e.question.startsWith('Apps fora'),
    );

    expect(entry.answer, 'Existe 1 app fora da proteção');
  });
}
