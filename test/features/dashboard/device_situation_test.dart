import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/dashboard/domain/device_situation.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';

void main() {
  group('DeviceSituation', () {
    test('tryParse reconhece IDs do wire', () {
      expect(DeviceSituation.tryParse('home'), DeviceSituation.home);
      expect(DeviceSituation.tryParse('trusted'), DeviceSituation.trusted);
      expect(DeviceSituation.tryParse('street'), DeviceSituation.street);
      expect(DeviceSituation.tryParse('transit'), DeviceSituation.transit);
      expect(DeviceSituation.tryParse('unknown'), DeviceSituation.unknown);
    });

    test('tryParse ignora ausente ou inválido', () {
      expect(DeviceSituation.tryParse(null), isNull);
      expect(DeviceSituation.tryParse(''), isNull);
      expect(DeviceSituation.tryParse('modo_casa'), isNull);
    });

    test('labels e hints PT iguais ao app', () {
      expect(DeviceSituation.home.labelPt, 'Casa');
      expect(DeviceSituation.home.hintPt, 'Ambiente confiável');
      expect(DeviceSituation.trusted.labelPt, 'Trabalho');
      expect(DeviceSituation.trusted.hintPt, 'Ambiente confiável');
      expect(DeviceSituation.street.labelPt, 'Rua');
      expect(DeviceSituation.street.hintPt, 'Proteção reforçada');
      expect(DeviceSituation.unknown.labelPt, 'Ambiente em análise');
    });
  });

  group('DeviceStatus situation', () {
    test('fromFirestore lê situation*', () {
      final status = DeviceStatus.fromFirestore('dev-1', {
        'situation': 'home',
        'situationConfidence': 0.87,
        'situationReasons': ['known_wifi', 'habitual_time'],
        'situationUpdatedAt': DateTime.utc(2026, 9, 14, 12),
        'lastSeen': DateTime.now(),
      });

      expect(status.situation, DeviceSituation.home);
      expect(status.hasSituation, isTrue);
      expect(status.situationConfidence, closeTo(0.87, 0.001));
      expect(status.situationReasons, ['known_wifi', 'habitual_time']);
      expect(status.situationUpdatedAt, DateTime.utc(2026, 9, 14, 12));
    });

    test('sem campos situation o badge não aparece', () {
      final status = DeviceStatus.fromFirestore('dev-1', {
        'lastSeen': DateTime.now(),
      });
      expect(status.situation, isNull);
      expect(status.hasSituation, isFalse);
      expect(status.situationReasons, isEmpty);
    });
  });
}
