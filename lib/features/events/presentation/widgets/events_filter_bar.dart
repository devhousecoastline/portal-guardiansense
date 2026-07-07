import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/events/domain/event_filters.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';
import 'package:guardian_portal/features/events/presentation/widgets/event_date_range_picker.dart';

class EventsFilterBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            if (filters.hasActiveFilters)
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Limpar'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _FilterRow(
          children: [
            for (final period in EventPeriod.values)
              _FilterChip(
                label: _periodLabel(period),
                selected:
                    filters.customRange == null && filters.period == period,
                onTap: () => onChanged(
                  filters.copyWith(period: period, clearCustomRange: true),
                ),
              ),
            _FilterChip(
              label: filters.customRange != null
                  ? EventFilters.formatCustomRange(filters.customRange!)
                  : 'Calendário',
              icon: Icons.calendar_month_rounded,
              selected: filters.customRange != null,
              onTap: () => _pickCustomRange(context),
            ),
          ],
        ),
        if (filters.customRange != null) ...[
          const SizedBox(height: 6),
          Text(
            'Período personalizado: ${EventFilters.formatCustomRange(filters.customRange!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
        const SizedBox(height: 8),
        _FilterRow(
          children: [
            _FilterChip(
              label: 'Todas severidades',
              selected: filters.severity == null,
              onTap: () => onChanged(filters.copyWith(clearSeverity: true)),
            ),
            for (final severity in SecurityEventSeverity.values)
              _FilterChip(
                label: _countedLabel(
                  _severityLabel(severity),
                  severityCounts[severity] ?? 0,
                ),
                selected: filters.severity == severity,
                color: _severityColor(severity),
                onTap: () => onChanged(filters.copyWith(severity: severity)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _FilterRow(
          children: [
            for (final category in EventCategoryFilter.values)
              _FilterChip(
                label: _countedLabel(
                  _categoryLabel(category),
                  categoryCounts[category] ?? 0,
                ),
                selected: filters.category == category,
                onTap: () => onChanged(filters.copyWith(category: category)),
              ),
          ],
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
      onChanged(
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

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
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
    final accent = color ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: icon != null
            ? Icon(
                icon,
                size: 16,
                color: selected ? accent : AppColors.textMuted,
              )
            : null,
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? accent : AppColors.textMuted,
        ),
        backgroundColor: AppColors.card,
        selectedColor: accent.withValues(alpha: 0.14),
        side: BorderSide(
          color: selected
              ? accent.withValues(alpha: 0.45)
              : AppColors.divider,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
