import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_header_chip.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';

/// Chip compacto de conexão do aparelho — usado no topo do dashboard.
class DeviceOnlineChip extends StatelessWidget {
  const DeviceOnlineChip({
    super.key,
    required this.status,
  });

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final presence = status.presence;
    final color = switch (presence) {
      DevicePresence.online => AppColors.trustHigh,
      DevicePresence.stale => AppColors.trustMedium,
      DevicePresence.offline => AppColors.textMuted,
    };
    final relative = formatRelativeTime(status.lastSeen);
    final label = switch (presence) {
      DevicePresence.online => 'Online · $relative',
      DevicePresence.stale => status.lastContactLabel,
      DevicePresence.offline => 'Offline · $relative',
    };

    return GuardianHeaderChip(
      label: label,
      color: color,
      leading: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
