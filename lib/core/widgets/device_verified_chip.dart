import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

/// Selo de identidade confirmada — aparelho ativo e verificado no portal.
class DeviceVerifiedChip extends StatelessWidget {
  const DeviceVerifiedChip({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.trustHigh;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: compact ? 14 : 15, color: accent),
          const SizedBox(width: 6),
          Text(
            compact ? 'Verificado' : 'Ativo e verificado',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
