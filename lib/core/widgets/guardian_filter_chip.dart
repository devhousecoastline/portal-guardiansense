import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

/// Chip de filtro no padrão do portal (Eventos / Localizar).
class GuardianFilterChip extends StatelessWidget {
  const GuardianFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Cor semântica (ex.: severidade); senão seleção neutra do portal.
    final accent = color ?? AppColors.textPrimary;
    final selectedFill = color == null
        ? AppColors.textMuted.withValues(alpha: 0.12)
        : accent.withValues(alpha: 0.14);
    final selectedBorder = color == null
        ? AppColors.textMuted.withValues(alpha: 0.45)
        : accent.withValues(alpha: 0.45);

    return FilterChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 15,
              color: selected ? accent : AppColors.textMuted,
            )
          : null,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: selected ? accent : AppColors.textMuted,
      ),
      backgroundColor: AppColors.card,
      selectedColor: selectedFill,
      side: BorderSide(
        color: selected ? selectedBorder : AppColors.divider,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}
