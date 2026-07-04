import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

/// Botão pill alinhado ao onboarding do app mobile ([_PillButton]).
class GuardianPillButton extends StatefulWidget {
  const GuardianPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
    this.iconLeading = false,
    this.neutral = false,
    this.fullWidth = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool iconLeading;
  final bool neutral;
  final bool fullWidth;

  @override
  State<GuardianPillButton> createState() => _GuardianPillButtonState();
}

class _GuardianPillButtonState extends State<GuardianPillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    final base = widget.neutral ? AppColors.textMuted : AppColors.trustHigh;
    final fg = enabled ? base : AppColors.textMuted;

    final iconWidget = widget.busy
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Icon(widget.icon, size: 19, color: fg);

    final pill = Material(
      color: enabled
          ? base.withValues(alpha: widget.neutral ? 0.10 : 0.16)
          : AppColors.textMuted.withValues(alpha: 0.08),
      shape: StadiumBorder(
        side: BorderSide(
          color: enabled
              ? base.withValues(alpha: widget.neutral ? 0.35 : 0.5)
              : AppColors.textMuted.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: widget.onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          child: Row(
            mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment:
                widget.fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              if (widget.iconLeading) ...[
                iconWidget,
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (!widget.iconLeading) ...[
                const SizedBox(width: 8),
                iconWidget,
              ],
            ],
          ),
        ),
      ),
    );

    if (!enabled || widget.neutral) return pill;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.trustHigh.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: pill,
      ),
    );
  }
}
