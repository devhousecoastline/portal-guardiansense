import 'dart:math' as math;

import 'package:guardian_portal/features/locate/domain/location_history_point.dart';
import 'package:intl/intl.dart';

/// Trecho parado / mesma área na trilha (agrupamento só na UI do portal).
class LocationHistoryCluster {
  LocationHistoryCluster(List<LocationHistoryPoint> points)
      : assert(points.isNotEmpty),
        points = List<LocationHistoryPoint>.unmodifiable(
          [...points]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt)),
        );

  /// Dentro do grupo: mais recente primeiro.
  final List<LocationHistoryPoint> points;

  /// Ponto exibido (mais recente do grupo).
  LocationHistoryPoint get representative => points.first;

  DateTime get firstAt => points.last.recordedAt;
  DateTime get lastAt => points.first.recordedAt;

  Duration get dwell => lastAt.difference(firstAt);

  int get sampleCount => points.length;

  bool get isStationary => sampleCount > 1;

  String? get sourceLabel => representative.sourceLabel;

  /// Ex.: `17:00–17:22` (mesmo dia) ou `11/09 23:50 – 12/09 00:10`.
  String timeRangeLabel({
    String clockPattern = 'HH:mm',
    String dayClockPattern = 'dd/MM HH:mm',
  }) {
    final start = firstAt.toLocal();
    final end = lastAt.toLocal();
    final clock = DateFormat(clockPattern);
    final dayClock = DateFormat(dayClockPattern);
    if (!isStationary) return dayClock.format(end);
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return '${clock.format(start)}–${clock.format(end)}';
    }
    return '${dayClock.format(start)} – ${dayClock.format(end)}';
  }

  /// Texto curto para a lista (“mesmo local · ~15 min”).
  String? get dwellLabel {
    if (!isStationary) return null;
    return 'mesmo local · ${formatDwell(dwell)}';
  }

  bool containsId(String id) => points.any((p) => p.id == id);
}

/// Agrupa pontos contíguos no tempo se estiverem a ≤ [maxDistanceM].
///
/// [points] pode vir em qualquer ordem. Crise (`background_crisis`) não
/// se mistura a outros pontos — cada amostra de crise fica sozinha.
List<LocationHistoryCluster> groupLocationHistory(
  Iterable<LocationHistoryPoint> points, {
  double maxDistanceM = 40,
}) {
  final chronological = points.toList()
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  if (chronological.isEmpty) return const [];

  final buckets = <List<LocationHistoryPoint>>[];
  var current = <LocationHistoryPoint>[chronological.first];

  for (var i = 1; i < chronological.length; i++) {
    final point = chronological[i];
    final prev = current.last;
    final crisisBreak = _isCrisis(point) || _isCrisis(prev);
    final near = distanceMeters(
          prev.lat,
          prev.lng,
          point.lat,
          point.lng,
        ) <=
        maxDistanceM;

    if (!crisisBreak && near) {
      current.add(point);
    } else {
      buckets.add(current);
      current = [point];
    }
  }
  buckets.add(current);

  // Lista do portal: mais recente primeiro.
  return [
    for (final bucket in buckets.reversed) LocationHistoryCluster(bucket),
  ];
}

bool _isCrisis(LocationHistoryPoint point) =>
    point.source == 'background_crisis';

/// Distância em metros (haversine).
double distanceMeters(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const earthRadiusM = 6371000.0;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * earthRadiusM * math.asin(math.sqrt(a));
}

double _toRad(double deg) => deg * math.pi / 180;

String formatDwell(Duration dwell) {
  final totalMin = dwell.inMinutes;
  if (totalMin < 1) return '< 1 min';
  if (totalMin < 60) return '~$totalMin min';
  final hours = totalMin ~/ 60;
  final mins = totalMin % 60;
  if (hours < 24) {
    if (mins == 0) return '~$hours h';
    return '~$hours h $mins min';
  }
  final days = hours ~/ 24;
  final remH = hours % 24;
  if (remH == 0) return '~$days d';
  return '~$days d $remH h';
}
