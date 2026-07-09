import 'package:flutter/material.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
import 'package:guardian_portal/core/navigation/navigation_loading_controller.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/theme/dashboard_typography.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';

class ProtectionChecklistCard extends StatelessWidget {
  const ProtectionChecklistCard({
    super.key,
    required this.status,
    this.compact = false,
    this.twoColumns,
    this.pairGrid = false,
    this.expandVertically = false,
  });

  final DeviceStatus status;
  final bool compact;

  /// Quando null, deriva de [AppLayout.checklistTwoColBreakpoint].
  final bool? twoColumns;
  final bool pairGrid;
  final bool expandVertically;

  @override
  Widget build(BuildContext context) {
    final layout = ProtectionSnapshot.checklistLayout(status);
    final mainWidth = AppLayout.mainAreaWidth(MediaQuery.sizeOf(context).width);
    final useTwoColumns = !pairGrid &&
        (twoColumns ?? (mainWidth >= AppLayout.checklistTwoColBreakpoint));
    final body = _ChecklistBody(
      layout: layout,
      compact: compact,
      useTwoColumns: useTwoColumns,
      pairGrid: pairGrid,
    );

    return SectionCard(
      expandVertically: expandVertically,
      padding: EdgeInsets.fromLTRB(
        20,
        compact ? 12 : 18,
        20,
        compact ? 8 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Respostas em segundos',
            style: DashboardTypography.cardTitle(context, compact: compact),
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              status.isOnline
                  ? 'Status em tempo real do aparelho.'
                  : 'Último estado conhecido do aparelho.',
              style: DashboardTypography.cardSubtitle(context),
            ),
          ],
          SizedBox(height: compact ? 8 : 12),
          if (expandVertically && !pairGrid)
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: body,
              ),
            )
          else if (expandVertically)
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: body,
              ),
            )
          else
            body,
        ],
      ),
    );
  }
}

class _ChecklistBody extends StatelessWidget {
  const _ChecklistBody({
    required this.layout,
    required this.compact,
    required this.useTwoColumns,
    required this.pairGrid,
  });

  final ChecklistLayout layout;
  final bool compact;
  final bool useTwoColumns;
  final bool pairGrid;

  @override
  Widget build(BuildContext context) {
    final iconEntries = [...layout.left, ...layout.right];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pairGrid)
          _ChecklistPairGrid(entries: iconEntries, compact: compact)
        else if (useTwoColumns && layout.right.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ChecklistColumn(entries: layout.left, compact: compact),
              ),
              SizedBox(width: compact ? 14 : 20),
              Expanded(
                child: _ChecklistColumn(entries: layout.right, compact: compact),
              ),
            ],
          )
        else
          _ChecklistColumn(entries: iconEntries, compact: compact),
        if (layout.fullWidth.isNotEmpty) ...[
          SizedBox(height: compact ? 2 : 4),
          for (final entry in layout.fullWidth)
            _ChecklistRow(
              entry: entry,
              fullWidth: true,
              compact: compact,
              onDetails: entry.question.startsWith('Último evento') &&
                      entry.answer != 'Nenhuma registrada'
                  ? () => NavigationLoadingScope.of(context)
                      .go(context, AppRoutes.events)
                  : entry.question.startsWith('Apps fora')
                      ? () => NavigationLoadingScope.of(context)
                          .go(context, AppRoutes.settings)
                      : null,
            ),
        ],
      ],
    );
  }
}

class _ChecklistPairGrid extends StatelessWidget {
  const _ChecklistPairGrid({
    required this.entries,
    required this.compact,
  });

  final List<ProtectionChecklistEntry> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ChecklistRow(
                entry: entries[i],
                compact: compact,
                tight: true,
              ),
            ),
            const SizedBox(width: 10),
            if (i + 1 < entries.length)
              Expanded(
                child: _ChecklistRow(
                  entry: entries[i + 1],
                  compact: compact,
                  tight: true,
                ),
              )
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
      if (i + 2 < entries.length) {
        rows.add(SizedBox(height: compact ? 4 : 6));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _ChecklistColumn extends StatelessWidget {
  const _ChecklistColumn({
    required this.entries,
    this.compact = false,
  });

  final List<ProtectionChecklistEntry> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          _ChecklistRow(entry: entry, compact: compact),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.entry,
    this.fullWidth = false,
    this.compact = false,
    this.tight = false,
    this.onDetails,
  });

  final ProtectionChecklistEntry entry;
  final bool fullWidth;
  final bool compact;
  final bool tight;
  final VoidCallback? onDetails;

  static IconData? _iconFor(String question) {
    if (question.startsWith('Meu celular')) return Icons.shield_outlined;
    if (question.startsWith('O Runtime')) return Icons.memory_rounded;
    if (question.startsWith('A Ostra')) return Icons.lock_outline_rounded;
    if (question.startsWith('Quando foi')) return Icons.sync_rounded;
    if (question.startsWith('Último evento')) {
      return Icons.notifications_active_outlined;
    }
    if (question.startsWith('Apps fora')) {
      return Icons.warning_amber_rounded;
    }
    if (question.startsWith('Qual é meu')) return Icons.percent_rounded;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.signal) {
      ChecklistSignal.ok => AppColors.trustHigh,
      ChecklistSignal.warn => AppColors.trustMedium,
      ChecklistSignal.alert => AppColors.riskCritical,
      ChecklistSignal.muted => AppColors.textMuted,
    };
    final icon = _iconFor(entry.question);
    final iconSize = tight ? 16.0 : 18.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: fullWidth ? (compact ? 3 : 4) : (tight ? 0 : (compact ? 6 : 10)),
        top: fullWidth ? (compact ? 4 : 6) : 0,
      ),
      child: Container(
        width: double.infinity,
        padding: fullWidth
            ? EdgeInsets.symmetric(
                horizontal: 12,
                vertical: compact ? 8 : 10,
              )
            : EdgeInsets.zero,
        decoration: fullWidth
            ? BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: icon != null
                  ? Icon(icon, size: iconSize, color: color.withValues(alpha: 0.9))
                  : Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4),
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
            ),
            SizedBox(width: tight ? 6 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.question,
                    style: DashboardTypography.mutedLabel(context),
                    maxLines: tight ? 2 : null,
                    overflow: tight ? TextOverflow.ellipsis : null,
                  ),
                  SizedBox(height: tight ? 1 : 2),
                  Text(
                    entry.answer,
                    style: DashboardTypography.emphasis(context, color: color),
                    maxLines: tight ? 2 : null,
                    overflow: tight ? TextOverflow.ellipsis : null,
                  ),
                  if (onDetails != null) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onDetails,
                      child: Text(
                        entry.question.startsWith('Apps fora')
                            ? 'Ajustar em Configurações →'
                            : 'Ver detalhes →',
                        style: DashboardTypography.emphasis(
                          context,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
