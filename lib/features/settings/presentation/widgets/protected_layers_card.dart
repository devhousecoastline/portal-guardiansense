import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';

class ProtectedLayersCard extends StatelessWidget {
  const ProtectedLayersCard({
    super.key,
    required this.status,
    this.layersItem,
  });

  final DeviceStatus status;
  final ProtectionSetupItem? layersItem;

  @override
  Widget build(BuildContext context) {
    final layers = status.protectedLayers;
    final hasSnapshot = status.hasProtectedLayersSnapshot;
    final active = ProtectedLayerSnapshot.activeSections(layers);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Camadas protegidas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (hasSnapshot && active.isNotEmpty)
                _CountBadge(count: ProtectedLayerSnapshot.totalActiveApps(layers)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle(hasSnapshot: hasSnapshot, active: active),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
          ),
          if (!hasSnapshot) ...[
            const SizedBox(height: 12),
            const _AwaitingSyncHint(),
          ] else if (active.isEmpty) ...[
            const SizedBox(height: 12),
            const _EmptyLayersHint(),
          ] else ...[
            const SizedBox(height: 14),
            ...active.map(
              (layer) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LayerRow(layer: layer, muted: !status.isOnline),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _subtitle({
    required bool hasSnapshot,
    required List<ProtectedLayerSummary> active,
  }) {
    if (!hasSnapshot) {
      if (layersItem?.done == true) {
        return 'Camadas ativas no app — aguardando resumo detalhado na próxima '
            'versão do app.';
      }
      return 'O app enviará o resumo por categoria quando sincronizar.';
    }
    return ProtectedLayerSnapshot.summarySubtitle(status.protectedLayers);
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.trustHigh.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        count == 1 ? '1 app' : '$count apps',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.trustHigh,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({required this.layer, required this.muted});

  final ProtectedLayerSummary layer;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final accent = muted ? AppColors.textMuted : AppColors.trustHigh;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              layer.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            layer.countLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _AwaitingSyncHint extends StatelessWidget {
  const _AwaitingSyncHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.hourglass_empty, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Abra o Guardian Sense no celular para sincronizar as camadas.',
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

class _EmptyLayersHint extends StatelessWidget {
  const _EmptyLayersHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: AppColors.trustMedium),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Nenhum app ativo nas camadas. Ajuste em Camadas protegidas no app.',
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
