import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
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
        ? 'Online · agora'
        : 'Offline · ${formatRelativeTime(lastSeen)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
