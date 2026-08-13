import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/devices/domain/device_pairing.dart';

void main() {
  group('DevicePairing.parseCode', () {
    test('normaliza código cru', () {
      expect(DevicePairing.parseCode(' ab-c2k9 '), 'ABC2K9');
    });

    test('extrai da URL pública do QR', () {
      expect(
        DevicePairing.parseCode('https://guardian-sense.com/pair?c=H3N7KQ'),
        'H3N7KQ',
      );
    });

    test('uriFor usa o domínio e o parâmetro c', () {
      expect(
        DevicePairing.uriFor('h3n7kq'),
        'https://guardian-sense.com/pair?c=H3N7KQ',
      );
    });
  });

  group('DevicePairing.isWellFormedCode', () {
    test('aceita 6 caracteres do alfabeto', () {
      expect(DevicePairing.isWellFormedCode('H3N7KQ'), isTrue);
    });

    test('rejeita tamanho errado e letras ambíguas', () {
      expect(DevicePairing.isWellFormedCode('H3N7K'), isFalse);
      expect(DevicePairing.isWellFormedCode('H3N7K0'), isFalse);
      expect(DevicePairing.isWellFormedCode('H3N7KO'), isFalse);
    });
  });

  test('isActiveAt respeita prazo e uso único', () {
    final now = DateTime.utc(2026, 8, 13, 13, 0);
    final pairing = DevicePairing(
      id: 'p1',
      code: 'H3N7KQ',
      createdAt: DateTime.utc(2026, 8, 13, 12, 56),
      expiresAt: DateTime.utc(2026, 8, 13, 13, 1),
      used: false,
    );

    expect(pairing.isActiveAt(now), isTrue);
    expect(pairing.isActiveAt(now.add(const Duration(minutes: 2))), isFalse);
    expect(
      DevicePairing(
        id: 'p1',
        code: 'H3N7KQ',
        createdAt: pairing.createdAt,
        expiresAt: pairing.expiresAt,
        used: true,
      ).isActiveAt(now),
      isFalse,
    );
  });
}
