import 'package:cloud_firestore/cloud_firestore.dart';

/// Última posição sincronizada pelo app mobile.
class DeviceLocation {
  const DeviceLocation({
    required this.lat,
    required this.lng,
    this.accuracyM,
    this.updatedAt,
    this.source,
  });

  final double lat;
  final double lng;
  final double? accuracyM;
  final DateTime? updatedAt;
  final String? source;

  static DeviceLocation? fromFirestore(Map<String, dynamic> data) {
    final raw = data['lastLocation'];
    if (raw is! Map) return null;

    final lat = (raw['lat'] as num?)?.toDouble();
    final lng = (raw['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final ts = data['locationUpdatedAt'];
    final updatedAt = ts is Timestamp ? ts.toDate() : null;

    return DeviceLocation(
      lat: lat,
      lng: lng,
      accuracyM: (raw['accuracyM'] as num?)?.toDouble(),
      updatedAt: updatedAt,
      source: data['locationSource'] as String?,
    );
  }

  String get accuracyLabel {
    final m = accuracyM;
    if (m == null) return '—';
    if (m < 20) return '±${m.round()} m (boa)';
    if (m < 100) return '±${m.round()} m';
    return '±${m.round()} m (baixa)';
  }
}
