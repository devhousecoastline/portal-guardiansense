import 'package:flutter/material.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';
import 'package:guardian_portal/features/settings/presentation/widgets/protected_layer_detail_dialog.dart';

class ProtectedLayersCard extends StatelessWidget {
  const ProtectedLayersCard({
    super.key,
    required this.status,
  });

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final layers = status.protectedLayers;
    final hasSnapshot = status.hasProtectedLayersSnapshot;
    final active = ProtectedLayerSnapshot.visibleSections(layers);
    final muted = !status.isOnline;

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
          const SizedBox(height: 6),
          Text(
            _subtitle(hasSnapshot: hasSnapshot, active: active),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            const SizedBox(height: 12),
            _LayersGrid(layers: active, muted: muted),
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
      return 'Abra o app no celular para sincronizar o resumo por categoria.';
    }
    return ProtectedLayerSnapshot.summarySubtitle(status.protectedLayers);
  }
}

class _LayersGrid extends StatelessWidget {
  const _LayersGrid({required this.layers, required this.muted});

  final List<ProtectedLayerSummary> layers;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.maxWidth);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            mainAxisExtent: 52,
          ),
          itemCount: layers.length,
          itemBuilder: (context, index) =>
              _LayerTile(layer: layers[index], muted: muted),
        );
      },
    );
  }

  static int _columnCount(double width) {
    if (width >= AppLayout.dashboardRowBreakpoint) return 4;
    if (width >= AppLayout.checklistTwoColBreakpoint) return 3;
    return 2;
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({required this.layer, required this.muted});

  final ProtectedLayerSummary layer;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final muted = this.muted;
    final accent = muted
        ? AppColors.textMuted
        : (layer.activeCount > 0
            ? AppColors.trustHigh
            : AppColors.trustMedium);
    final warn = muted ? AppColors.textMuted : AppColors.trustMedium;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          showProtectedLayerDetailDialog(context, layer, muted: muted);
        },
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(layer.icon, color: accent, size: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        layer.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.1,
                            ),
                      ),
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                height: 1.15,
                              ),
                          children: _statusSpans(accent: accent, warn: warn),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _statusSpans({
    required Color accent,
    required Color warn,
  }) {
    if (layer.unprotectedCount == 0) {
      return [
        TextSpan(
          text: layer.protectedLabel,
          style: TextStyle(color: accent, fontWeight: FontWeight.w600),
        ),
      ];
    }

    return [
      TextSpan(
        text: layer.protectedLabel,
        style: TextStyle(color: accent, fontWeight: FontWeight.w600),
      ),
      const TextSpan(
        text: ' · ',
        style: TextStyle(color: AppColors.textMuted),
      ),
      TextSpan(
        text: layer.unprotectedLabel,
        style: TextStyle(color: warn, fontWeight: FontWeight.w500),
      ),
    ];
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
