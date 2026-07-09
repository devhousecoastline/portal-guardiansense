import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';

Future<void> showProtectedLayerDetailSheet(
  BuildContext context,
  ProtectedLayerSummary layer, {
  required bool muted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: _initialSize(layer),
      minChildSize: 0.28,
      maxChildSize: 0.85,
      builder: (_, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(layer.icon, color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layer.displayTitle,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _headerSubtitle(layer),
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            if (layer.apps.isEmpty) ...[
              const _AppsUnavailableHint(),
            ] else ...[
              for (final app in layer.apps) ...[
                _AppRow(app: app, muted: muted),
                const SizedBox(height: 6),
              ],
            ],
            const SizedBox(height: 12),
            Text(
              'Para alterar a proteção, abra Camadas protegidas no app Guardian Sense.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
            ),
          ],
        );
      },
    ),
  );
}

double _initialSize(ProtectedLayerSummary layer) {
  final rows = layer.apps.isEmpty ? 3 : layer.apps.length + 4;
  return (0.22 + rows * 0.055).clamp(0.32, 0.75);
}

String _headerSubtitle(ProtectedLayerSummary layer) {
  if (layer.unprotectedCount == 0) {
    return layer.protectedLabel;
  }
  return '${layer.protectedLabel} · ${layer.unprotectedLabel}';
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.muted});

  final ProtectedLayerAppSummary app;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final protected = app.protected;
    final accent = muted
        ? AppColors.textMuted
        : (protected ? AppColors.trustHigh : AppColors.trustMedium);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              protected ? Icons.verified_user : Icons.warning_amber_rounded,
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    protected ? 'Protegido' : 'Fora da proteção',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppsUnavailableHint extends StatelessWidget {
  const _AppsUnavailableHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.sync, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Lista de apps ainda não sincronizada. Abra o Guardian Sense no celular para atualizar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}
