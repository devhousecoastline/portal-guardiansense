import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';

enum DeviceCommandType {
  closeOyster,
  protectApp,
  protectApps,
  unknown;

  static DeviceCommandType parse(String? raw) => switch (raw) {
        'close_oyster' => DeviceCommandType.closeOyster,
        'protect_app' => DeviceCommandType.protectApp,
        'protect_apps' => DeviceCommandType.protectApps,
        _ => DeviceCommandType.unknown,
      };

  String get storageKey => switch (this) {
        DeviceCommandType.closeOyster => 'close_oyster',
        DeviceCommandType.protectApp => 'protect_app',
        DeviceCommandType.protectApps => 'protect_apps',
        DeviceCommandType.unknown => 'unknown',
      };
}

enum DeviceCommandStatus {
  pending,
  applied,
  failed,
  unknown;

  static DeviceCommandStatus parse(String? raw) => switch (raw) {
        'pending' => DeviceCommandStatus.pending,
        'applied' => DeviceCommandStatus.applied,
        'failed' => DeviceCommandStatus.failed,
        _ => DeviceCommandStatus.unknown,
      };

  String get storageKey => switch (this) {
        DeviceCommandStatus.pending => 'pending',
        DeviceCommandStatus.applied => 'applied',
        DeviceCommandStatus.failed => 'failed',
        DeviceCommandStatus.unknown => 'unknown',
      };
}

class DeviceCommand {
  const DeviceCommand({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.requestedBy,
    this.reason,
    this.appliedAt,
    this.failureMessage,
    this.packageName,
    this.label,
    this.sectionId,
    this.apps = const [],
    this.appCount,
  });

  final String id;
  final DeviceCommandType type;
  final DeviceCommandStatus status;
  final DateTime createdAt;
  final String requestedBy;
  final String? reason;
  final DateTime? appliedAt;
  final String? failureMessage;
  final String? packageName;
  final String? label;
  final String? sectionId;
  final List<ProtectAppCommandTarget> apps;
  final int? appCount;

  bool get isPending => status == DeviceCommandStatus.pending;
  bool get isApplied => status == DeviceCommandStatus.applied;
  bool get isFailed => status == DeviceCommandStatus.failed;

  factory DeviceCommand.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DeviceCommand(
      id: doc.id,
      type: DeviceCommandType.parse(data['type'] as String?),
      status: DeviceCommandStatus.parse(data['status'] as String?),
      createdAt: _timestamp(data['createdAt']) ?? DateTime.now(),
      requestedBy: data['requestedBy'] as String? ?? '',
      reason: data['reason'] as String?,
      appliedAt: _timestamp(data['appliedAt']),
      failureMessage: data['failureMessage'] as String?,
      packageName: data['packageName'] as String?,
      label: data['label'] as String?,
      sectionId: data['sectionId'] as String?,
      apps: ProtectAppCommandTarget.fromFirestoreList(data['apps']),
      appCount: (data['appCount'] as num?)?.toInt(),
    );
  }

  static DateTime? _timestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
