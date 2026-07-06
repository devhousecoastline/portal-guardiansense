import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/locate/application/location_geocode_service.dart';

void main() {
  group('LocationGeocodeService._formatAddress', () {
    test('monta rua, bairro e cidade', () {
      final label = LocationGeocodeService.formatAddressForTest({
        'address': {
          'road': 'Rua das Flores',
          'suburb': 'Centro',
          'city': 'São Paulo',
        },
      });
      expect(label, 'Rua das Flores, Centro, São Paulo');
    });

    test('usa display_name truncado como fallback', () {
      final label = LocationGeocodeService.formatAddressForTest({
        'display_name': 'Praça, Bairro, Cidade, Estado, País',
      });
      expect(label, 'Praça, Bairro, Cidade');
    });
  });
}
