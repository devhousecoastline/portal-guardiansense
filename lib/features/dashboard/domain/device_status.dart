import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/features/dashboard/domain/device_location.dart';

/// Estado de proteção sincronizado pelo app mobile (read-only no portal).
enum ProtectionLevel { protected, partial, alert, offline, unknown }

class DeviceStatus {
  const DeviceStatus({
    required this.deviceId,
    required this.modelLabel,
    required this.platform,
    required this.appVersion,
    required this.lastSeen,
    required this.protectionIndex,
    required this.runtimeActive,
    required this.oysterClosed,
    required this.batteryLevel,
    required this.lastAlertAt,
    required this.lastAlertSummary,
    required this.lastEventAt,
    required this.lastEventSummary,
    required this.location,
    required this.isOnline,
    required this.level,
  });

  final String deviceId;
  final String modelLabel;
  final String platform;
  final String appVersion;
  final DateTime? lastSeen;
  final int protectionIndex;
  final bool? runtimeActive;
  final bool? oysterClosed;
  final int? batteryLevel;
  final DateTime? lastAlertAt;
  final String? lastAlertSummary;
  final DateTime? lastEventAt;
  final String? lastEventSummary;
  final DeviceLocation? location;
  final bool isOnline;
  final ProtectionLevel level;

  String get protectionLabel => switch (level) {
        ProtectionLevel.protected => 'Protegido',
        ProtectionLevel.partial => 'Parcial',
        ProtectionLevel.alert => 'Alerta',
        ProtectionLevel.offline => 'Offline',
        ProtectionLevel.unknown => 'Aguardando sync',
      };

  static DeviceStatus fromFirestore(String id, Map<String, dynamic> data) {
    final lastSeen = _timestamp(data['lastSeen']) ?? _timestamp(data['lastSync']);
    final now = DateTime.now();
    final online = lastSeen != null &&
        now.difference(lastSeen) < AppConstants.deviceOnlineThreshold;

    final runtimeActive = data['runtimeActive'] as bool?;
    final oysterClosed = data['oysterClosed'] as bool?;
    final protectionIndex = _protectionIndex(data, runtimeActive, oysterClosed, online);

    return DeviceStatus(
      deviceId: id,
      modelLabel: data['modelLabel'] as String? ??
          data['model'] as String? ??
          'Dispositivo',
      platform: data['platform'] as String? ?? '—',
      appVersion: data['appVersion'] as String? ?? '—',
      lastSeen: lastSeen,
      protectionIndex: protectionIndex,
      runtimeActive: runtimeActive,
      oysterClosed: oysterClosed,
      batteryLevel: (data['batteryLevel'] as num?)?.toInt(),
      lastAlertAt: _timestamp(data['lastAlertAt']),
      lastAlertSummary: data['lastAlertSummary'] as String?,
      lastEventAt: _timestamp(data['lastEventAt']),
      lastEventSummary: data['lastEventSummary'] as String?,
      location: DeviceLocation.fromFirestore(data),
      isOnline: online,
      level: _level(protectionIndex, online, runtimeActive, oysterClosed),
    );
  }

  static int _protectionIndex(
    Map<String, dynamic> data,
    bool? runtimeActive,
    bool? oysterClosed,
    bool online,
  ) {
    final stored = (data['protectionIndex'] as num?)?.toInt();
    if (stored != null) return stored.clamp(0, 100);
    if (!online) return 0;
    if (runtimeActive == true && oysterClosed == true) return 100;
    if (runtimeActive == true) return 75;
    if (runtimeActive == false) return 25;
    return 50;
  }

  static ProtectionLevel _level(
    int index,
    bool online,
    bool? runtimeActive,
    bool? oysterClosed,
  ) {
    if (!online) return ProtectionLevel.offline;
    if (runtimeActive == null && oysterClosed == null) {
      return ProtectionLevel.unknown;
    }
    if (index >= 90) return ProtectionLevel.protected;
    if (index >= 50) return ProtectionLevel.partial;
    return ProtectionLevel.alert;
  }

  static DateTime? _timestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
