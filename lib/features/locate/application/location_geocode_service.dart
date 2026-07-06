import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Endereço aproximado via Nominatim (OpenStreetMap) — sem Google Maps.
class LocationGeocodeService {
  LocationGeocodeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final Map<String, String> _cache = {};

  Future<String?> reverseGeocode(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'lat': '$lat',
          'lon': '$lng',
          'format': 'json',
          'zoom': '18',
          'addressdetails': '1',
        },
      );

      final response = await _client.get(
        uri,
        headers: const {
          'User-Agent': 'GuardianSensePortal/1.0 (locate; contact: portal)',
          'Accept-Language': 'pt-BR,pt;q=0.9',
        },
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;

      final label = formatAddress(data);
      if (label != null) _cache[key] = label;
      return label;
    } catch (e, st) {
      debugPrint('reverseGeocode falhou: $e\n$st');
      return null;
    }
  }

  @visibleForTesting
  static String? formatAddressForTest(Map<String, dynamic> data) =>
      formatAddress(data);

  static String? formatAddress(Map<String, dynamic> data) {
    final address = data['address'];
    if (address is Map) {
      final map = Map<String, dynamic>.from(address);
      final road = map['road'] ?? map['pedestrian'] ?? map['footway'];
      final suburb = map['suburb'] ?? map['neighbourhood'] ?? map['quarter'];
      final city = map['city'] ??
          map['town'] ??
          map['village'] ??
          map['municipality'];
      final parts = <String>[
        if (road != null) '$road',
        if (suburb != null) '$suburb',
        if (city != null) '$city',
      ];
      if (parts.isNotEmpty) return parts.join(', ');
    }

    final display = data['display_name'] as String?;
    if (display == null || display.isEmpty) return null;
    final segments = display.split(',').take(3).join(',').trim();
    return segments.isEmpty ? null : segments;
  }
}
