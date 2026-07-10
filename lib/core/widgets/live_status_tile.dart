import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/theme/dashboard_typography.dart';

/// Tile compacto com ícone, rótulo e valor — usado em estado ao vivo e camadas.
class LiveStatusTile extends StatelessWidget {
  const LiveStatusTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback? onTap;

  /// Grade densa (camadas) — mesmo visual, menos padding e uma linha no valor.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = accent;
    final hPad = compact ? 10.0 : 14.0;
    final vPad = compact ? 8.0 : 12.0;
    final iconSize = compact ? 18.0 : 20.0;
    final gap = compact ? 8.0 : 10.0;
    final valueGap = compact ? 2.0 : 4.0;
    final radius = compact ? 10.0 : 12.0;

    final tile = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: color.withValues(alpha: 0.95)),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardTypography.mutedLabel(context),
                ),
                SizedBox(height: valueGap),
                Text(
                  value,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardTypography.emphasis(context, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: tile,
      ),
    );
  }
}

Color liveStatusAccent({
  required bool muted,
  required bool ok,
  required bool warn,
}) {
  if (muted) return AppColors.textMuted;
  if (warn) return AppColors.trustMedium;
  if (ok) return AppColors.trustHigh;
  return AppColors.textMuted;
}
