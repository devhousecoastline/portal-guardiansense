import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/events/data/events_repository.dart';
import 'package:guardian_portal/features/events/domain/event_filters.dart';
import 'package:guardian_portal/features/events/domain/events_timeline_builder.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';
import 'package:guardian_portal/features/events/presentation/widgets/events_filter_bar.dart';
import 'package:guardian_portal/features/events/presentation/widgets/events_timeline.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  EventFilterState _filters = EventFilterState.initial;
  final _refreshController = OnlineRefreshController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder(
      stream: DeviceRepository().watchDeviceList(uid),
      builder: (context, deviceSnap) {
        if (deviceSnap.connectionState == ConnectionState.waiting &&
            !deviceSnap.hasData) {
          return const GuardianScaffold(
            title: 'Eventos',
            subtitle: 'Linha do tempo de segurança',
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final deviceList = deviceSnap.data;
        final primary = deviceList?.visible.isNotEmpty == true
            ? deviceList!.visible.first
            : null;
        final subtitle = primary == null
            ? 'Linha do tempo de segurança'
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
                  title: 'Eventos',
                  subtitle: subtitle,
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
                        _EventsBody(
                          rawEvents: snapshot.data ?? [],
                          filters: _filters,
                          onFiltersChanged: (filters) =>
                              setState(() => _filters = filters),
                          onClearFilters: () =>
                              setState(() => _filters = EventFilterState.initial),
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

class _EventsBody extends StatelessWidget {
  const _EventsBody({
    required this.rawEvents,
    required this.filters,
    required this.onFiltersChanged,
    required this.onClearFilters,
  });

  final List<SecurityEvent> rawEvents;
  final EventFilterState filters;
  final ValueChanged<EventFilterState> onFiltersChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final baseFilters = EventFilterState(
      period: filters.period,
      customRange: filters.customRange,
    );
    final inPeriod = EventFilters.apply(rawEvents, baseFilters);
    final filteredEvents = EventFilters.apply(rawEvents, filters);
    final timeline = EventsTimelineBuilder.build(filteredEvents);

    if (rawEvents.isEmpty) {
      return  SectionCard(
        child: Column(
          children: [
            Icon(Icons.timeline_outlined, size: 40, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Nenhum evento sincronizado ainda.\n'
              'Quando o app enviar alertas à nuvem, eles aparecerão aqui.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final stats = EventFilters.stats(inPeriod, filteredEvents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: EventsFilterBar(
            filters: filters,
            onChanged: onFiltersChanged,
            onClear: onClearFilters,
            severityCounts: EventFilters.severityCounts(inPeriod),
            categoryCounts: EventFilters.categoryCounts(inPeriod),
          ),
        ),
        const SizedBox(height: 14),
        if (timeline.isEmpty)
          SectionCard(
            child: Column(
              children: [
                Icon(
                  Icons.filter_list_off_outlined,
                  size: 36,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhum evento com esses filtros.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tente ampliar o período ou limpar os filtros.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onClearFilters,
                  child: const Text('Limpar filtros'),
                ),
              ],
            ),
          )
        else ...[
          EventsStatsBar(stats: stats),
          EventsTimeline(entries: timeline),
        ],
      ],
    );
  }
}
