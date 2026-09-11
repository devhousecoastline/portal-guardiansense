import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/locate/domain/location_history_cluster.dart';
import 'package:guardian_portal/features/locate/domain/location_history_point.dart';

LocationHistoryPoint _p({
  required String id,
  required DateTime at,
  double lat = -29.76777,
  double lng = -50.02235,
  String? source = 'background',
}) {
  return LocationHistoryPoint(
    id: id,
    lat: lat,
    lng: lng,
    recordedAt: at,
    source: source,
  );
}

void main() {
  final t0 = DateTime(2026, 9, 11, 17, 0);

  test('agrupa pontos próximos no tempo e espaço', () {
    final points = [
      _p(id: '3', at: t0.add(const Duration(minutes: 10))),
      _p(id: '2', at: t0.add(const Duration(minutes: 5)), lat: -29.76776),
      _p(id: '1', at: t0),
    ];

    final clusters = groupLocationHistory(points);
    expect(clusters, hasLength(1));
    expect(clusters.first.sampleCount, 3);
    expect(clusters.first.representative.id, '3');
    expect(clusters.first.dwellLabel, 'mesmo local · ~10 min');
    expect(clusters.first.timeRangeLabel(), '17:00–17:10');
  });

  test('timeRangeLabel cruza meia-noite', () {
    final points = [
      _p(id: '1', at: DateTime(2026, 9, 11, 23, 50)),
      _p(id: '2', at: DateTime(2026, 9, 12, 0, 10)),
    ];
    final cluster = groupLocationHistory(points).single;
    expect(
      cluster.timeRangeLabel(),
      '11/09 23:50 – 12/09 00:10',
    );
  });

  test('quebra quando a distância passa do limiar', () {
    final points = [
      _p(id: 'a', at: t0),
      // ~111 m a norte (0.001°) — acima de 40 m
      _p(id: 'b', at: t0.add(const Duration(minutes: 5)), lat: -29.76677),
    ];

    final clusters = groupLocationHistory(points);
    expect(clusters, hasLength(2));
    expect(clusters.every((c) => !c.isStationary), isTrue);
  });

  test('crise não entra no agrupamento estacionário', () {
    final points = [
      _p(id: '1', at: t0),
      _p(
        id: 'crisis',
        at: t0.add(const Duration(minutes: 3)),
        source: 'background_crisis',
      ),
      _p(id: '2', at: t0.add(const Duration(minutes: 6))),
    ];

    final clusters = groupLocationHistory(points);
    expect(clusters, hasLength(3));
    expect(clusters.map((c) => c.representative.id), ['2', 'crisis', '1']);
  });

  test('formatDwell cobre faixas', () {
    expect(formatDwell(Duration.zero), '< 1 min');
    expect(formatDwell(const Duration(minutes: 15)), '~15 min');
    expect(formatDwell(const Duration(hours: 2)), '~2 h');
    expect(formatDwell(const Duration(hours: 2, minutes: 10)), '~2 h 10 min');
    expect(formatDwell(const Duration(days: 1)), '~1 d');
  });
}
