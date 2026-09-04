import 'package:flutter/material.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
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

  /// Grade densa (aparelho e camadas) — canto suave, menos padding e uma linha no valor.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = accent;
    final hPad = compact ? 10.0 : 14.0;
    final vPad = compact ? 8.0 : 10.0;
    final iconSize = compact ? 18.0 : 20.0;
    final gap = compact ? 8.0 : 10.0;
    final valueGap = compact ? 2.0 : 4.0;
    // Grade (camadas e aparelho): canto suave. compact: false = pill.
    final radius = compact ? 10.0 : 99.0;

    final tile = Container(
      width: compact ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: color.withValues(alpha: 0.95)),
          SizedBox(width: gap),
          if (compact)
            Expanded(child: _LiveStatusTexts(
              label: label,
              value: value,
              color: color,
              valueGap: valueGap,
              compact: compact,
            ))
          else
            _LiveStatusTexts(
              label: label,
              value: value,
              color: color,
              valueGap: valueGap,
              compact: compact,
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

class _LiveStatusTexts extends StatelessWidget {
  const _LiveStatusTexts({
    required this.label,
    required this.value,
    required this.color,
    required this.valueGap,
    required this.compact,
  });

  final String label;
  final String value;
  final Color color;
  final double valueGap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

/// Grade responsiva dos tiles de status — mesma densidade em aparelho e camadas.
class LiveStatusGrid extends StatelessWidget {
  const LiveStatusGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnCount(constraints.maxWidth);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 56,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  static int columnCount(double width) {
    if (width >= AppLayout.dashboardRowBreakpoint) return 4;
    if (width >= AppLayout.checklistTwoColBreakpoint) return 3;
    return 2;
  }
}
