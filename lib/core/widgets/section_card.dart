import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.expandVertically = false,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool expandVertically;

  /// Faixa de 4px à esquerda — mesmo idioma dos tiles de Dispositivos.
  final Color? accentColor;

  static const _accentWidth = 4.0;

  @override
  Widget build(BuildContext context) {
    final hasAccent = accentColor != null;
    final contentPadding = hasAccent
        ? padding.copyWith(left: padding.left + _accentWidth)
        : padding;

    final paddedChild = Padding(
      padding: contentPadding,
      child: child,
    );

    return Container(
      width: double.infinity,
      height: expandVertically ? double.infinity : null,
      alignment: Alignment.topLeft,
      clipBehavior: hasAccent ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: hasAccent
          ? Stack(
              fit: expandVertically ? StackFit.expand : StackFit.loose,
              children: [
                paddedChild,
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _accentWidth,
                  child: ColoredBox(color: accentColor!),
                ),
              ],
            )
          : paddedChild,
    );
  }
}

class MetricRow extends StatelessWidget {
  const MetricRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
