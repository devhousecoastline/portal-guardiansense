import 'package:cloud_firestore/cloud_firestore.dart';

/// Ponto da trilha em `users/{uid}/devices/{deviceId}/locations/{pointId}`.
class LocationHistoryPoint {
  const LocationHistoryPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.accuracyM,
    this.source,
    this.quality,
  });

  final String id;
  final double lat;
  final double lng;
  final DateTime recordedAt;
  final double? accuracyM;
  final String? source;
  final String? quality;

  factory LocationHistoryPoint.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['recordedAt'];
    final recordedAt = ts is Timestamp ? ts.toDate() : DateTime.now();

    return LocationHistoryPoint(
      id: doc.id,
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      accuracyM: (data['accuracyM'] as num?)?.toDouble(),
      recordedAt: recordedAt,
      source: data['source'] as String?,
      quality: data['quality'] as String?,
    );
  }

  String? get sourceLabel => switch (source) {
        'foreground' => 'App em uso',
        'background' => 'Segundo plano',
        'background_crisis' => 'Crise',
        null || '' => null,
        final s => s,
      };
}
