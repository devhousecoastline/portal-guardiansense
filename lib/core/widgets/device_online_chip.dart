import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_header_chip.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';

/// Chip compacto de conexão do aparelho — usado no topo do dashboard.
class DeviceOnlineChip extends StatelessWidget {
  const DeviceOnlineChip({
    super.key,
    required this.isOnline,
    this.lastSeen,
  });

  final bool isOnline;
  final DateTime? lastSeen;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.trustHigh : AppColors.textMuted;
    final label = isOnline
        ? 'Online · ${formatRelativeTime(lastSeen)}'
        : 'Offline · ${formatRelativeTime(lastSeen)}';

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
