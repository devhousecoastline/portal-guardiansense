import 'package:flutter/material.dart';

/// Chip de cabeçalho — mesmo recuo e tipo em Centro, Conta e status de plano.
class GuardianHeaderChip extends StatelessWidget {
  const GuardianHeaderChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.leading,
    this.expand = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final Widget? leading;

  /// Preenche a largura do pai (ex.: empilhar chips com a mesma largura).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ?leading,
          if (leading == null && icon != null)
            Icon(icon, size: 15, color: color),
          if (leading != null || icon != null) const SizedBox(width: 8),
          if (expand)
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            )
          else
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
