import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';

Future<void> showProtectedLayerDetailDialog(
  BuildContext context,
  ProtectedLayerSummary layer, {
  required bool muted,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _ProtectedLayerDetailDialog(layer: layer, muted: muted),
  );
}

class _ProtectedLayerDetailDialog extends StatelessWidget {
  const _ProtectedLayerDetailDialog({
    required this.layer,
    required this.muted,
  });

  final ProtectedLayerSummary layer;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.42;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DialogAccentIcon(
                    child: Icon(layer.icon, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            layer.displayTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _headerSubtitle(layer),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (layer.apps.isEmpty)
                const _AppsUnavailableHint()
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: layer.apps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, index) => _AppRow(
                      app: layer.apps[index],
                      muted: muted,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Para alterar a proteção, abra Camadas protegidas no app Guardian Sense.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _headerSubtitle(ProtectedLayerSummary layer) {
  if (layer.unprotectedCount == 0) {
    return layer.protectedLabel;
  }
  return '${layer.protectedLabel} · ${layer.unprotectedLabel}';
}

class _DialogAccentIcon extends StatelessWidget {
  const _DialogAccentIcon({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
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
      ),
    );
  }
}
