import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';

class ProtectionSetupCard extends StatelessWidget {
  const ProtectionSetupCard({super.key, required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final complete = status.hasSetupChecklist &&
        status.pendingSetupItems.isEmpty &&
        status.configuredSetupItems.isNotEmpty;

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurações do aparelho',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            complete
                ? 'Todos os requisitos do app estão em dia.'
                : 'O que falta ajustar no app para chegar a 100%.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 14),
          if (!status.isOnline) ...[
            _InfoBanner(
              text: status.hasSetupChecklist
                  ? 'Aparelho offline — dados podem estar desatualizados.'
                  : 'Aparelho offline — abra o app no celular para sincronizar.',
            ),
            const SizedBox(height: 12),
          ],
          if (!status.hasSetupChecklist)
            Text(
              'Abra o Guardian Sense no celular com esta conta para '
              'sincronizar o checklist.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            )
          else ...[
            _ProgressSummary(status: status, complete: complete),
            const SizedBox(height: 16),
            if (complete)
              _CompleteGrid(items: status.configuredSetupItems)
            else ...[
              if (status.pendingSetupItems.isNotEmpty) ...[
                _SectionTitle(
                  label: 'Ainda falta (${status.pendingSetupItems.length})',
                  color: AppColors.trustMedium,
                ),
                const SizedBox(height: 6),
                ...status.pendingSetupItems.map(
                  (item) => _PendingRow(item: item),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ajuste no app → Configurações.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
              if (status.configuredSetupItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ConfiguredExpansion(items: status.configuredSetupItems),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.status, required this.complete});

  final DeviceStatus status;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final total = status.protectionSetupItems.length;
    final done = status.configuredSetupItems.length;
    final ratio = total == 0 ? 0.0 : done / total;
    final color = complete ? AppColors.trustHigh : AppColors.trustMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (complete)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.trustHigh.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.trustHigh.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: AppColors.trustHigh,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$done de $total requisitos configurados',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.trustHigh,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            '$done de $total requisitos',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.textMuted.withValues(alpha: 0.12),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CompleteGrid extends StatelessWidget {
  const _CompleteGrid({required this.items});

  final List<ProtectionSetupItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 320;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return SizedBox(
              width: twoColumns
                  ? (constraints.maxWidth - 8) / 2
                  : constraints.maxWidth,
              child: _SetupChip(item: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SetupChip extends StatelessWidget {
  const _SetupChip({required this.item});

  final ProtectionSetupItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.trustHigh.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.trustHigh.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_rounded,
            size: 16,
            color: AppColors.trustHigh,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.25,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.item});

  final ProtectionSetupItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.trustMedium.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.trustMedium.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppColors.trustMedium,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pendente no app',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.trustMedium,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfiguredExpansion extends StatelessWidget {
  const _ConfiguredExpansion({required this.items});

  final List<ProtectionSetupItem> items;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4, bottom: 4),
        title: Text(
          'Já ajustado no app (${items.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.trustHigh,
                fontWeight: FontWeight.w600,
              ),
        ),
        iconColor: AppColors.trustHigh,
        collapsedIconColor: AppColors.textMuted,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.trustHigh,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
      ),
    );
  }
}
