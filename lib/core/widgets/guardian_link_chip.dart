import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

/// CTA compacto de link/ação — usado em cards do Centro.
class GuardianLinkChip extends StatefulWidget {
  const GuardianLinkChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.compact = false,
    this.external = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool compact;

  /// Ícone padrão vira [Icons.open_in_new_rounded] se true e [icon] for o default.
  final bool external;

  @override
  State<GuardianLinkChip> createState() => _GuardianLinkChipState();
}

class _GuardianLinkChipState extends State<GuardianLinkChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final accent = AppColors.primary;
    final fg = enabled
        ? accent
        : AppColors.textMuted.withValues(alpha: 0.55);
    final trailing = widget.external &&
            widget.icon == Icons.arrow_forward_rounded
        ? Icons.open_in_new_rounded
        : widget.icon;
    final vPad = widget.compact ? 6.0 : 8.0;
    final hPad = widget.compact ? 10.0 : 12.0;
    final fontSize = widget.compact ? 12.0 : 13.0;
    final iconSize = widget.compact ? 14.0 : 15.0;

    final chip = Material(
      color: enabled
          ? accent.withValues(alpha: _hovered ? 0.16 : 0.10)
          : AppColors.textMuted.withValues(alpha: 0.06),
      shape: StadiumBorder(
        side: BorderSide(
          color: enabled
              ? accent.withValues(alpha: _hovered ? 0.55 : 0.35)
              : AppColors.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: widget.onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 6),
              Icon(trailing, size: iconSize, color: fg),
            ],
          ),
        ),
      ),
    );

    if (!enabled) return chip;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -1 : 0, 0),
        child: chip,
      ),
    );
  }
}
