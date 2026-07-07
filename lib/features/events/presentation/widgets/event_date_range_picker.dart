import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

/// Seletor de período com calendários inline (sem dialog aninhado no web).
Future<DateTimeRange?> showEventDateRangePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  required DateTimeRange initialRange,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    builder: (dialogContext) {
      return _EventDateRangeDialog(
        firstDate: _dateOnly(firstDate),
        lastDate: _dateOnly(lastDate),
        initialRange: DateTimeRange(
          start: _dateOnly(initialRange.start),
          end: _dateOnly(initialRange.end),
        ),
      );
    },
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class _EventDateRangeDialog extends StatefulWidget {
  const _EventDateRangeDialog({
    required this.firstDate,
    required this.lastDate,
    required this.initialRange,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange initialRange;

  @override
  State<_EventDateRangeDialog> createState() => _EventDateRangeDialogState();
}

class _EventDateRangeDialogState extends State<_EventDateRangeDialog>
    with SingleTickerProviderStateMixin {
  late DateTime _start;
  late DateTime _end;
  late TabController _tabController;
  static final _fmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange.start;
    _end = widget.initialRange.end;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onStartChanged(DateTime value) {
    final day = _dateOnly(value);
    setState(() {
      _start = day;
      if (_end.isBefore(_start)) _end = _start;
    });
  }

  void _onEndChanged(DateTime value) {
    final day = _dateOnly(value);
    setState(() {
      _end = day.isBefore(_start) ? _start : day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _pickerTheme(context);

    return Theme(
      data: theme,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selecione o período',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fmt.format(_start)} — ${_fmt.format(_end)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Início · ${_fmt.format(_start)}'),
                  Tab(text: 'Fim · ${_fmt.format(_end)}'),
                ],
              ),
              SizedBox(
                height: 340,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CalendarDatePicker(
                      key: ValueKey('start-$_start'),
                      initialDate: _start,
                      firstDate: widget.firstDate,
                      lastDate: widget.lastDate,
                      currentDate: widget.lastDate,
                      onDateChanged: _onStartChanged,
                    ),
                    CalendarDatePicker(
                      key: ValueKey('end-$_end'),
                      initialDate: _end,
                      firstDate: _start,
                      lastDate: widget.lastDate,
                      currentDate: widget.lastDate,
                      onDateChanged: _onEndChanged,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(
                          DateTimeRange(start: _start, end: _end),
                        ),
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ThemeData _pickerTheme(BuildContext context) {
  return Theme.of(context).copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.card,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.card,
      headerBackgroundColor: AppColors.surface,
      headerForegroundColor: AppColors.textPrimary,
      weekdayStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
      dayStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
      todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
      todayBackgroundColor: WidgetStateProperty.all(
        AppColors.primary.withValues(alpha: 0.12),
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.textMuted.withValues(alpha: 0.35);
        }
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return Colors.transparent;
      }),
    ),
  );
}
