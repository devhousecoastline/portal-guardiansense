import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/events/domain/event_filters.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';
import 'package:guardian_portal/features/events/presentation/widgets/event_date_range_picker.dart';

class EventsFilterBar extends StatefulWidget {
  const EventsFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
    required this.onClear,
    required this.severityCounts,
    required this.categoryCounts,
  });

  final EventFilterState filters;
  final ValueChanged<EventFilterState> onChanged;
  final VoidCallback onClear;
  final Map<SecurityEventSeverity, int> severityCounts;
  final Map<EventCategoryFilter, int> categoryCounts;

  @override
  State<EventsFilterBar> createState() => _EventsFilterBarState();
}

class _EventsFilterBarState extends State<EventsFilterBar> {
  /// Começa fechado para liberar a timeline; o resumo mostra o recorte ativo.
  var _expanded = false;

  EventFilterState get filters => widget.filters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterHeader(
          expanded: _expanded,
          hasActiveFilters: filters.hasActiveFilters,
          summary: _summaryLabel(filters),
          onToggle: () => setState(() => _expanded = !_expanded),
          onClear: widget.onClear,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ScrollChips(
                        children: [
                          for (final period in EventPeriod.values)
                            _FilterChip(
                              label: _periodLabel(period),
                              selected: filters.customRange == null &&
                                  filters.period == period,
                              onTap: () => widget.onChanged(
                                filters.copyWith(
                                  period: period,
                                  clearCustomRange: true,
                                ),
                              ),
                            ),
                          _FilterChip(
                            label: filters.customRange != null
                                ? EventFilters.formatCustomRange(
                                    filters.customRange!,
                                  )
                                : 'Calendário',
                            icon: Icons.calendar_month_rounded,
                            selected: filters.customRange != null,
                            onTap: () => _pickCustomRange(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _ScrollChips(
                        children: [
                          _FilterChip(
                            label: 'Todas sev.',
                            selected: filters.severity == null,
                            onTap: () => widget.onChanged(
                              filters.copyWith(clearSeverity: true),
                            ),
                          ),
                          for (final severity in SecurityEventSeverity.values)
                            _FilterChip(
                              label: _countedLabel(
                                _severityLabel(severity),
                                widget.severityCounts[severity] ?? 0,
                              ),
                              selected: filters.severity == severity,
                              color: _severityColor(severity),
                              onTap: () => widget.onChanged(
                                filters.copyWith(severity: severity),
                              ),
                            ),
                          const _ChipDivider(),
                          for (final category in EventCategoryFilter.values)
                            _FilterChip(
                              label: _countedLabel(
                                _categoryLabel(category),
                                widget.categoryCounts[category] ?? 0,
                              ),
                              selected: filters.category == category,
                              onTap: () => widget.onChanged(
                                filters.copyWith(category: category),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day);
    final firstDate = lastDate.subtract(const Duration(days: 365));

    final initialRange = _clampDateRange(
      filters.customRange ??
          DateTimeRange(
            start: lastDate.subtract(const Duration(days: 6)),
            end: lastDate,
          ),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    try {
      final picked = await showEventDateRangePicker(
        context,
        firstDate: firstDate,
        lastDate: lastDate,
        initialRange: initialRange,
      );

      if (picked == null) return;
      widget.onChanged(
        filters.copyWith(
          period: EventPeriod.all,
          customRange: _clampDateRange(
            picked,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir o calendário: $error'),
        ),
      );
    }
  }

  static DateTimeRange _clampDateRange(
    DateTimeRange range, {
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    var start = DateTime(range.start.year, range.start.month, range.start.day);
    var end = DateTime(range.end.year, range.end.month, range.end.day);

    if (start.isBefore(firstDate)) start = firstDate;
    if (end.isAfter(lastDate)) end = lastDate;
    if (start.isAfter(end)) start = end;

    return DateTimeRange(start: start, end: end);
  }

  static String _summaryLabel(EventFilterState filters) {
    final period = filters.customRange != null
        ? EventFilters.formatCustomRange(filters.customRange!)
        : _periodLabel(filters.period);
    final severity = filters.severity == null
        ? 'Todas sev.'
        : _severityLabel(filters.severity!);
    final category = _categoryLabel(filters.category);
    return '$period · $severity · $category';
  }

  static String _periodLabel(EventPeriod period) => switch (period) {
        EventPeriod.today => 'Hoje',
        EventPeriod.last7Days => '7 dias',
        EventPeriod.last30Days => '30 dias',
        EventPeriod.all => 'Tudo',
      };

  static String _severityLabel(SecurityEventSeverity severity) =>
      switch (severity) {
        SecurityEventSeverity.critical => 'Crítico',
        SecurityEventSeverity.warning => 'Atenção',
        SecurityEventSeverity.info => 'Info',
      };

  static Color? _severityColor(SecurityEventSeverity severity) =>
      switch (severity) {
        SecurityEventSeverity.critical => AppColors.riskCritical,
        SecurityEventSeverity.warning => AppColors.riskElevated,
        SecurityEventSeverity.info => AppColors.textMuted,
      };

  static String _categoryLabel(EventCategoryFilter category) =>
      switch (category) {
        EventCategoryFilter.all => 'Todos tipos',
        EventCategoryFilter.oyster => 'Ostra',
        EventCategoryFilter.risk => 'Risco',
        EventCategoryFilter.protection => 'Proteção',
        EventCategoryFilter.blocked => 'Bloqueio',
      };

  static String _countedLabel(String label, int count) => '$label ($count)';
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({
    required this.expanded,
    required this.hasActiveFilters,
    required this.summary,
    required this.onToggle,
    required this.onClear,
  });

  final bool expanded;
  final bool hasActiveFilters;
  final String summary;
  final VoidCallback onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'Filtros',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (!expanded) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasActiveFilters
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontWeight: hasActiveFilters
                                ? FontWeight.w600
                                : FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasActiveFilters)
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(left: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Limpar'),
          ),
      ],
    );
  }
}

class _ScrollChips extends StatelessWidget {
  const _ScrollChips({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    );
  }
}

class _ChipDivider extends StatelessWidget {
  const _ChipDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.divider,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Severidade mantém cor semântica; período/tipo usam seleção neutra.
    final accent = color ?? AppColors.textPrimary;
    final selectedFill = color == null
        ? AppColors.textMuted.withValues(alpha: 0.12)
        : accent.withValues(alpha: 0.14);
    final selectedBorder = color == null
        ? AppColors.textMuted.withValues(alpha: 0.45)
        : accent.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        avatar: icon != null
            ? Icon(
                icon,
                size: 15,
                color: selected ? accent : AppColors.textMuted,
              )
            : null,
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: selected ? accent : AppColors.textMuted,
        ),
        backgroundColor: AppColors.card,
        selectedColor: selectedFill,
        side: BorderSide(
          color: selected ? selectedBorder : AppColors.divider,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }
}
