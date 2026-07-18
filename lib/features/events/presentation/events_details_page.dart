import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/events/data/events_repository.dart';
import 'package:guardian_portal/features/events/domain/event_display.dart';
import 'package:guardian_portal/features/events/domain/event_filters.dart';
import 'package:guardian_portal/features/events/domain/event_timeline_entry.dart';
import 'package:guardian_portal/features/events/domain/events_timeline_builder.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';
import 'package:guardian_portal/features/events/presentation/widgets/event_tile.dart';

class EventsDetailsPage extends StatefulWidget {
  const EventsDetailsPage({super.key, required this.day});

  final DateTime day;

  @override
  State<EventsDetailsPage> createState() => _EventsDetailsPageState();
}

class _EventsDetailsPageState extends State<EventsDetailsPage> {
  final _refreshController = OnlineRefreshController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final day = EventFilters.calendarDay(widget.day);
    final dayLabel = EventFilters.dayLabelFor(day);

    return StreamBuilder(
      stream: DeviceRepository().watchDeviceList(uid),
      builder: (context, deviceSnap) {
        final deviceList = deviceSnap.data;
        final primary = deviceList?.visible.isNotEmpty == true
            ? deviceList!.visible.first
            : null;
        final subtitle = primary == null
            ? 'Detalhes do dia'
            : 'Aparelho: ${primary.status.modelLabel}';

        final eventsStream = primary == null
            ? Stream<List<SecurityEvent>>.value(const [])
            : EventsRepository().watchForDevice(uid, primary.id);

        return StreamBuilder<List<SecurityEvent>>(
          stream: eventsStream,
          builder: (context, snapshot) {
            final initialLoad =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

            return OnlineRefresh(
              controller: _refreshController,
              builder: (context, isRefreshing) {
                return GuardianScaffold(
                  title: 'Eventos · $dayLabel',
                  subtitle: subtitle,
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.events);
                    }
                  },
                  onRefresh: _refreshController.refresh,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RefreshTickBar(
                        visible: isRefreshing && snapshot.hasData,
                      ),
                      if (initialLoad)
                        const Center(child: CircularProgressIndicator())
                      else if (snapshot.hasError)
                        SectionCard(
                          child: Text(
                            'Não foi possível carregar eventos.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        _DayDetailsBody(
                          day: day,
                          dayLabel: dayLabel,
                          rawEvents: snapshot.data ?? const [],
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DayDetailsBody extends StatelessWidget {
  const _DayDetailsBody({
    required this.day,
    required this.dayLabel,
    required this.rawEvents,
  });

  final DateTime day;
  final String dayLabel;
  final List<SecurityEvent> rawEvents;

  @override
  Widget build(BuildContext context) {
    final timeline = EventsTimelineBuilder.build(rawEvents);
    EventTimelineEntry? entry;
    for (final candidate in timeline) {
      if (EventFilters.isSameCalendarDay(candidate.summary.occurredAt, day)) {
        entry = candidate;
        break;
      }
    }

    if (entry == null) {
      return SectionCard(
        child: Column(
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 36,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum evento em $dayLabel.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.events),
              child: const Text('Voltar para Eventos'),
            ),
          ],
        ),
      );
    }

    final summary = entry.summary;
    final dayEvents = entry.dayEvents;
    final status = EventDisplay.statusLabel(summary);
    final time = EventTile.formatOccurredAt(summary.occurredAt, showDate: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Último evento',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '$time · $status',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                EventDisplay.title(summary),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${dayEvents.length} registro(s) neste dia',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final event in dayEvents) ...[
          _EventDetailRow(event: event),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _EventDetailRow extends StatelessWidget {
  const _EventDetailRow({required this.event});

  final SecurityEvent event;

  @override
  Widget build(BuildContext context) {
    final time = EventTile.formatOccurredAt(event.occurredAt, showDate: false);
    final status = EventDisplay.statusLabel(event);
    final title = EventDisplay.title(event);
    final subtitle = EventDisplay.subtitle(event);
    final color = event.isNormalSession
        ? AppColors.trustHigh
        : EventTile.severityColor(event.severity);

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
              ),
              const Spacer(),
              _SeverityPill(label: event.severityLabel, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
      ),
    );
  }
}
