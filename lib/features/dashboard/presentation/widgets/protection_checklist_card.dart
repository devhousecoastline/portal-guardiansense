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
          if (expandVertically)
            Expanded(
              child: _ChecklistBody(
                layout: layout,
                compact: compact,
                useTwoColumns: useTwoColumns,
                pairGrid: pairGrid,
                pinFooter: true,
              ),
            )
          else
            _ChecklistBody(
              layout: layout,
              compact: compact,
              useTwoColumns: useTwoColumns,
              pairGrid: pairGrid,
            ),
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
    this.pinFooter = false,
  });

  final ChecklistLayout layout;
  final bool compact;
  final bool useTwoColumns;
  final bool pairGrid;

  /// Empurra "Último evento" (fullWidth) para a base do card.
  final bool pinFooter;

  /// Largura mínima do card para os blocos de rodapé caberem lado a lado.
  static const _sideBySideFooterWidth = 300.0;

  /// Sem altura fixa há espaço para empilhar; só divide em cards realmente largos.
  static const _sideBySideFooterWidthLoose = 560.0;

  bool _sideBySideFooter(double maxWidth) {
    if (layout.fullWidth.length < 2) return false;
    return maxWidth >=
        (pinFooter ? _sideBySideFooterWidth : _sideBySideFooterWidthLoose);
  }

  VoidCallback? _onDetails(
    BuildContext context,
    ProtectionChecklistEntry entry,
  ) {
    if (entry.question.startsWith('Último evento')) {
      if (entry.answer == 'Nenhuma registrada') return null;
      return () =>
          NavigationLoadingScope.of(context).go(context, AppRoutes.events);
    }
    if (entry.question.startsWith('Apps fora')) {
      return () =>
          NavigationLoadingScope.of(context).go(context, AppRoutes.settings);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final iconEntries = [...layout.left, ...layout.right];

    final grid = pairGrid
        ? _ChecklistPairGrid(entries: iconEntries, compact: compact)
        : useTwoColumns && layout.right.isNotEmpty
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                        _ChecklistColumn(entries: layout.left, compact: compact),
                  ),
                  SizedBox(width: compact ? 14 : 20),
                  Expanded(
                    child: _ChecklistColumn(
                      entries: layout.right,
                      compact: compact,
                    ),
                  ),
                ],
              )
            : _ChecklistColumn(entries: iconEntries, compact: compact);

    return LayoutBuilder(
      builder: (context, constraints) {
        final footer = _buildFooter(
          context,
          sideBySide: _sideBySideFooter(constraints.maxWidth),
        );

        if (!pinFooter) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              grid,
              if (footer != null) ...[
                SizedBox(height: compact ? 8 : 10),
                footer,
              ],
            ],
          );
        }

        // Altura fixa da célula: preenche quando sobra espaço, rola quando falta.
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  grid,
                  if (footer != null) ...[
                    const Spacer(),
                    SizedBox(height: compact ? 8 : 10),
                    footer,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget? _buildFooter(BuildContext context, {required bool sideBySide}) {
    if (layout.fullWidth.isEmpty) return null;

    final gap = compact ? 8.0 : 10.0;
    final row = <Widget>[];
    final column = <Widget>[];

    for (final entry in layout.fullWidth) {
      final tile = _ChecklistFooterTile(
        entry: entry,
        compact: compact,
        onTap: _onDetails(context, entry),
      );
      if (row.isNotEmpty) {
        row.add(SizedBox(width: gap));
        column.add(SizedBox(height: gap));
      }
      row.add(Expanded(child: tile));
      column.add(tile);
    }

    return Padding(
      padding: EdgeInsets.only(top: compact ? 4 : 6),
      child: sideBySide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: row,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: column,
            ),
    );
  }
}

/// Bloco de rodapé — tile inteiro clicável, com chevron à direita.
class _ChecklistFooterTile extends StatelessWidget {
  const _ChecklistFooterTile({
    required this.entry,
    required this.compact,
    this.onTap,
  });

  final ProtectionChecklistEntry entry;
  final bool compact;
  final VoidCallback? onTap;

  /// Espaço das duas linhas que o texto ocupa nas colunas estreitas — reservá-lo
  /// mantém a mesma altura quando o bloco aparece sozinho em largura total.
  static double _textBlockHeight(TextStyle question, TextStyle answer) {
    double twoLines(TextStyle style) =>
        (style.fontSize ?? 12) * (style.height ?? 1.2) * 2;
    return twoLines(question) + 2 + twoLines(answer);
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.signal) {
      ChecklistSignal.ok => AppColors.trustHigh,
      ChecklistSignal.warn => AppColors.trustMedium,
      ChecklistSignal.alert => AppColors.riskCritical,
      ChecklistSignal.muted => AppColors.textMuted,
    };
    final icon = _ChecklistRow._iconFor(entry.question);
    final radius = BorderRadius.circular(10);
    final questionStyle = DashboardTypography.mutedLabel(context);
    final answerStyle = DashboardTypography.emphasis(context, color: color);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: radius,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 8 : 10,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: _textBlockHeight(questionStyle, answerStyle),
              ),
              child: Row(
                children: [
                  icon != null
                      ? Icon(icon, size: 16, color: color.withValues(alpha: 0.9))
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.question,
                          style: questionStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.answer,
                          style: answerStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
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
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ChecklistTile(
                  entry: entries[i],
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: i + 1 < entries.length
                    ? _ChecklistTile(
                        entry: entries[i + 1],
                        compact: compact,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < entries.length) {
        rows.add(SizedBox(height: compact ? 8 : 10));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// Célula uniforme da grade 2×2 — mesma altura na linha, padding e tipografia.
class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.entry,
    required this.compact,
  });

  final ProtectionChecklistEntry entry;
  final bool compact;

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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 12,
        compact ? 8 : 10,
        compact ? 10 : 12,
        compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: icon != null
                ? Icon(icon, size: 16, color: color.withValues(alpha: 0.9))
                : Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  entry.question,
                  style: DashboardTypography.mutedLabel(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.answer,
                  style: DashboardTypography.emphasis(context, color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
    this.compact = false,
  });

  final ProtectionChecklistEntry entry;
  final bool compact;

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
    const iconSize = 18.0;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 10),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.question,
                  style: DashboardTypography.mutedLabel(context),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.answer,
                  style: DashboardTypography.emphasis(context, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
