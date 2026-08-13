import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/features/dashboard/domain/device_location.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';

/// Estado de proteção sincronizado pelo app mobile (read-only no portal).
enum ProtectionLevel { protected, partial, alert, offline, unknown }

/// Vínculo do doc em `users/{uid}/devices/{deviceId}.status`.
enum DeviceBindingStatus { active, released, unknown }

class DeviceStatus {
  const DeviceStatus({
    required this.deviceId,
    required this.modelLabel,
    required this.platform,
    required this.appVersion,
    required this.lastSeen,
    required this.storedProtectionIndex,
    required this.runtimeActive,
    required this.oysterClosed,
    required this.batteryLevel,
    required this.lastAlertAt,
    required this.lastAlertSummary,
    required this.lastEventAt,
    required this.lastEventSummary,
    required this.location,
    required this.fingerprint,
    required this.protectionSetupItems,
    required this.protectedLayers,
    this.bindingStatus = DeviceBindingStatus.active,
    this.releasedAt,
    this.verified,
    this.verifiedAt,
    this.verifiedVia,
  });

  final String deviceId;
  final String modelLabel;
  final String platform;
  final String appVersion;
  final DateTime? lastSeen;
  final int storedProtectionIndex;
  final bool? runtimeActive;
  final bool? oysterClosed;
  final int? batteryLevel;
  final DateTime? lastAlertAt;
  final String? lastAlertSummary;
  final DateTime? lastEventAt;
  final String? lastEventSummary;
  final DeviceLocation? location;
  final String? fingerprint;
  final List<ProtectionSetupItem> protectionSetupItems;
  final List<ProtectedLayerSummary> protectedLayers;
  final DeviceBindingStatus bindingStatus;
  final DateTime? releasedAt;

  /// `null` = legado (aparelho anterior ao QR) — o portal trata como verificado.
  /// `false` = ainda não confirmou identidade; não sincroniza no portal.
  final bool? verified;
  final DateTime? verifiedAt;
  final String? verifiedVia;

  bool get isReleased => bindingStatus == DeviceBindingStatus.released;

  /// Portão da nuvem: sem verificação o portal não mostra o aparelho.
  bool get isVerified => verified != false;

  bool get isQrVerified => verified == true && verifiedVia == 'qr';

  bool get hasSetupChecklist => protectionSetupItems.isNotEmpty;

  bool get hasProtectedLayersSnapshot => protectedLayers.isNotEmpty;

  List<ProtectionSetupItem> get configuredSetupItems =>
      protectionSetupItems.where((i) => i.done).toList(growable: false);

  List<ProtectionSetupItem> get pendingSetupItems =>
      protectionSetupItems.where((i) => !i.done).toList(growable: false);

  /// Online se houve sync recente (recalculado a cada build/tick).
  bool get isOnline {
    if (isReleased) return false;
    final seen = lastSeen;
    if (seen == null) return false;
    return DateTime.now().difference(seen) < AppConstants.deviceOnlineThreshold;
  }

  int get protectionIndex => isOnline ? storedProtectionIndex : 0;

  ProtectionLevel get level =>
      _level(storedProtectionIndex, isOnline, runtimeActive, oysterClosed);

  String get protectionLabel => switch (level) {
        ProtectionLevel.protected => 'Protegido',
        ProtectionLevel.partial => 'Parcial',
        ProtectionLevel.alert => 'Alerta',
        ProtectionLevel.offline => 'Offline',
        ProtectionLevel.unknown => 'Aguardando sync',
      };

  static DeviceStatus fromFirestore(String id, Map<String, dynamic> data) {
    final lastSeen = _timestamp(data['lastSeen']) ?? _timestamp(data['lastSync']);
    final runtimeActive = data['runtimeActive'] as bool?;
    final oysterClosed = data['oysterClosed'] as bool?;
    final protectionIndex =
        _protectionIndex(data, runtimeActive, oysterClosed);

    return DeviceStatus(
      deviceId: id,
      modelLabel: data['modelLabel'] as String? ??
          data['model'] as String? ??
          'Dispositivo',
      platform: data['platform'] as String? ?? '—',
      appVersion: data['appVersion'] as String? ?? '—',
      lastSeen: lastSeen,
      storedProtectionIndex: protectionIndex,
      runtimeActive: runtimeActive,
      oysterClosed: oysterClosed,
      batteryLevel: (data['batteryLevel'] as num?)?.toInt(),
      lastAlertAt: _timestamp(data['lastAlertAt']),
      lastAlertSummary: data['lastAlertSummary'] as String?,
      lastEventAt: _timestamp(data['lastEventAt']),
      lastEventSummary: data['lastEventSummary'] as String?,
      location: DeviceLocation.fromFirestore(data),
      fingerprint: data['fingerprint'] as String?,
      protectionSetupItems:
          ProtectionSetupItem.fromFirestoreList(data['protectionChecklist']),
      protectedLayers:
          ProtectedLayerSummary.fromFirestoreList(data['protectedLayers']),
      bindingStatus: _bindingStatus(data['status']),
      releasedAt: _timestamp(data['releasedAt']),
      verified: data['verified'] as bool?,
      verifiedAt: _timestamp(data['verifiedAt']),
      verifiedVia: data['verifiedVia'] as String?,
    );
  }

  static DeviceBindingStatus _bindingStatus(Object? value) {
    final raw = (value as String?)?.trim().toLowerCase();
    return switch (raw) {
      'released' => DeviceBindingStatus.released,
      'active' => DeviceBindingStatus.active,
      null || '' => DeviceBindingStatus.active, // legado sem campo
      _ => DeviceBindingStatus.unknown,
    };
  }

  static int _protectionIndex(
    Map<String, dynamic> data,
    bool? runtimeActive,
    bool? oysterClosed,
  ) {
    final stored = (data['protectionIndex'] as num?)?.toInt();
    if (stored != null) return stored.clamp(0, 100);
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
