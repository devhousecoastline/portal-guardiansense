import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/theme/dashboard_typography.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';

class ProtectionSetupCard extends StatelessWidget {
  const ProtectionSetupCard({
    super.key,
    required this.status,
    this.stretchVertically = false,
    this.fillHeight = false,
    this.compact = false,
  });

  final DeviceStatus status;
  final bool stretchVertically;
  final bool fillHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = !status.isOnline;
    final complete = status.hasSetupChecklist &&
        status.pendingSetupItems.isEmpty &&
        status.configuredSetupItems.isNotEmpty;
    final expands = stretchVertically || fillHeight;

    return SizedBox(
      width: double.infinity,
      height: expands ? double.infinity : null,
      child: SectionCard(
        expandVertically: expands,
        padding: EdgeInsets.fromLTRB(
          20,
          compact ? 12 : 18,
          20,
          compact ? 8 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            'Configurações do aparelho',
            style: DashboardTypography.cardTitle(context, compact: compact),
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              ProtectionSnapshot.setupCardSubtitle(status),
              style: DashboardTypography.cardSubtitle(context),
            ),
          ],
            SizedBox(height: compact ? 10 : 16),
            if (!status.hasSetupChecklist)
              Text(
                status.isOnline
                    ? 'Abra o Guardian Sense no celular com esta conta para '
                        'sincronizar o checklist.'
                    : 'Abra o app no celular para sincronizar quando voltar online.',
                style: DashboardTypography.cardSubtitle(context),
              )
            else ...[
              _ProgressSummary(
                status: status,
                complete: complete,
                muted: muted,
                compact: compact,
              ),
              SizedBox(height: compact ? 10 : 16),
              if (complete)
                fillHeight
                    ? Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: _CompleteGrid(
                            items: status.configuredSetupItems,
                            muted: muted,
                            compact: compact,
                          ),
                        ),
                      )
                    : _CompleteGrid(
                        items: status.configuredSetupItems,
                        muted: muted,
                        compact: compact,
                      )
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
                  style: DashboardTypography.mutedLabel(context),
                ),
              ],
              if (status.configuredSetupItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ConfiguredList(
                  items: status.configuredSetupItems,
                  muted: muted,
                ),
              ],
            ],
          ],
          if (fillHeight && !complete) const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.status,
    required this.complete,
    required this.muted,
    this.compact = false,
  });

  final DeviceStatus status;
  final bool complete;
  final bool muted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final total = status.protectionSetupItems.length;
    final done = status.configuredSetupItems.length;
    final ratio = total == 0 ? 0.0 : done / total;
    final accent = muted
        ? AppColors.textMuted
        : (complete ? AppColors.trustHigh : AppColors.trustMedium);

    final label = muted
        ? 'Última sync: $done de $total requisitos'
        : (complete
            ? '$done de $total requisitos configurados'
            : '$done de $total requisitos');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (complete)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Icon(
                  muted ? Icons.history_rounded : Icons.verified_rounded,
                  size: 20,
                  color: accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    muted ? '$label (pode estar desatualizado)' : label,
                    style: DashboardTypography.highlightCaption(
                      context,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Text(label, style: DashboardTypography.highlightCaption(context)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.textMuted.withValues(alpha: 0.12),
            color: accent,
          ),
        ),
      ],
    );
  }
}

class _CompleteGrid extends StatelessWidget {
  const _CompleteGrid({
    required this.items,
    required this.muted,
    this.compact = false,
  });

  final List<ProtectionSetupItem> items;
  final bool muted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SetupChip(item: items[i], muted: muted, compact: compact)),
            const SizedBox(width: 8),
            if (i + 1 < items.length)
              Expanded(
                child: _SetupChip(
                  item: items[i + 1],
                  muted: muted,
                  compact: compact,
                ),
              )
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
      if (i + 2 < items.length) rows.add(SizedBox(height: compact ? 6 : 8));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _SetupChip extends StatelessWidget {
  const _SetupChip({
    required this.item,
    required this.muted,
    this.compact = false,
  });

  final ProtectionSetupItem item;
  final bool muted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = muted ? AppColors.textMuted : AppColors.trustHigh;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            muted ? Icons.check_rounded : Icons.check_rounded,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              style: DashboardTypography.emphasis(
                context,
                color: muted ? AppColors.textMuted : null,
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
                  style: DashboardTypography.emphasis(context),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pendente no app',
                  style: DashboardTypography.emphasis(
                    context,
                    color: AppColors.trustMedium,
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

class _ConfiguredList extends StatelessWidget {
  const _ConfiguredList({required this.items, required this.muted});

  final List<ProtectionSetupItem> items;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final accent = muted ? AppColors.textMuted : AppColors.trustHigh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Já ajustado no app (${items.length})',
          style: DashboardTypography.highlightCaption(context, color: accent),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: DashboardTypography.mutedLabel(context).copyWith(
                          color: muted ? AppColors.textMuted : AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
      style: DashboardTypography.highlightCaption(context, color: color),
    );
  }
}
