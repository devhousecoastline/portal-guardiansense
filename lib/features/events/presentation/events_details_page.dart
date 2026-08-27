import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/core/widgets/premium_feature_gate.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/subscription/domain/premium_features.dart';
import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/events/data/events_repository.dart';
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

    return PremiumFeatureGate(
      featureName: 'Eventos',
      hasAccess: PremiumFeatures.events,
      scaffoldTitle: 'Eventos · $dayLabel',
      scaffoldSubtitle: 'Detalhes do dia',
      onRefresh: _refreshController.refresh,
      child: StreamBuilder(
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
                  onRefresh: _refreshController.refresh,
                  fitViewport: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RefreshTickBar(
                        visible: isRefreshing && snapshot.hasData,
                      ),
                      Expanded(
                        child: initialLoad
                            ? const Center(child: CircularProgressIndicator())
                            : snapshot.hasError
                                ? SectionCard(
                                    child: Text(
                                      'Não foi possível carregar eventos.\n${snapshot.error}',
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : _DayDetailsBody(
                                    day: day,
                                    dayLabel: dayLabel,
                                    rawEvents: snapshot.data ?? const [],
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ),
    );
  }
}

class _DayDetailsBody extends StatefulWidget {
  const _DayDetailsBody({
    required this.day,
    required this.dayLabel,
    required this.rawEvents,
  });

  final DateTime day;
  final String dayLabel;
  final List<SecurityEvent> rawEvents;

  @override
  State<_DayDetailsBody> createState() => _DayDetailsBodyState();
}

class _DayDetailsBodyState extends State<_DayDetailsBody> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeline = EventsTimelineBuilder.build(widget.rawEvents);
    EventTimelineEntry? entry;
    for (final candidate in timeline) {
      if (EventFilters.isSameCalendarDay(
        candidate.summary.occurredAt,
        widget.day,
      )) {
        entry = candidate;
        break;
      }
    }

    if (entry == null) {
      return Center(
        child: SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 36,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhum evento em ${widget.dayLabel}.',
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
        ),
      );
    }

    final dayEvents = entry.dayEvents;
    final count = dayEvents.length;
    final countLabel =
        '$count ${count == 1 ? 'registro' : 'registros'} neste dia';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.insights_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  countLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView.separated(
              controller: _scrollController,
              primary: false,
              padding: const EdgeInsets.only(right: 14, bottom: 28),
              itemCount: dayEvents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return EventTile(
                  event: dayEvents[index],
                  showDate: false,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
