import 'package:flutter/material.dart';

/// Pill de cabeçalho — mesmo recuo e tipo em Centro, Conta e status de plano.
class GuardianHeaderChip extends StatelessWidget {
  const GuardianHeaderChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.leading,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
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
          ?leading,
          if (leading == null && icon != null)
            Icon(icon, size: 15, color: color),
          if (leading != null || icon != null) const SizedBox(width: 8),
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
