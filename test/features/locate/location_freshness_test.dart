import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/locate/domain/location_freshness.dart';

void main() {
  group('LocationFreshness', () {
    test('isStale é false dentro do limite', () {
      final recent = DateTime.now().subtract(const Duration(minutes: 10));
      expect(LocationFreshness.isStale(recent), isFalse);
    });

    test('isStale é true após 30 minutos', () {
      final old = DateTime.now().subtract(const Duration(minutes: 31));
      expect(LocationFreshness.isStale(old), isTrue);
    });

    test('isStale é true sem data', () {
      expect(LocationFreshness.isStale(null), isTrue);
    });

    test('staleMessage offline enfatiza sincronização', () {
      final old = DateTime.now().subtract(const Duration(hours: 1));
      final msg = LocationFreshness.staleMessage(old, deviceOnline: false);
      expect(msg, contains('offline'));
    });

    test('staleMessage null quando posição recente', () {
      final recent = DateTime.now().subtract(const Duration(minutes: 5));
      expect(LocationFreshness.staleMessage(recent, deviceOnline: true), isNull);
    });
  });
}
