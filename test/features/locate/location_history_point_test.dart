import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/locate/domain/location_history_point.dart';

void main() {
  test('sourceLabel cobre foreground, background e crise', () {
    final at = DateTime(2026, 9, 11, 12);
    expect(
      LocationHistoryPoint(
        id: 'a',
        lat: 1,
        lng: 2,
        recordedAt: at,
        source: 'foreground',
      ).sourceLabel,
      'App em uso',
    );
    expect(
      LocationHistoryPoint(
        id: 'b',
        lat: 1,
        lng: 2,
        recordedAt: at,
        source: 'background',
      ).sourceLabel,
      'Segundo plano',
    );
    expect(
      LocationHistoryPoint(
        id: 'c',
        lat: 1,
        lng: 2,
        recordedAt: at,
        source: 'background_crisis',
      ).sourceLabel,
      'Crise',
    );
  });
}
