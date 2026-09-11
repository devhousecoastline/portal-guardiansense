import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_filter_chip.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/core/widgets/premium_feature_gate.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/application/dashboard_service.dart';
import 'package:guardian_portal/features/dashboard/domain/device_location.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';
import 'package:guardian_portal/features/events/presentation/widgets/event_date_range_picker.dart';
import 'package:guardian_portal/features/locate/data/location_history_repository.dart';
import 'package:guardian_portal/features/locate/domain/location_history_cluster.dart';
import 'package:guardian_portal/features/locate/domain/location_history_point.dart';
import 'package:guardian_portal/features/locate/presentation/widgets/guardian_device_map.dart';
import 'package:guardian_portal/features/locate/presentation/widgets/location_history_list.dart';
import 'package:guardian_portal/features/locate/presentation/widgets/location_info_card.dart';
import 'package:guardian_portal/features/subscription/domain/premium_features.dart';
import 'package:intl/intl.dart';

enum _LocateMode { current, history }

enum _HistoryWindow { hours24, days7, days30, custom }

class LocatePage extends StatefulWidget {
  const LocatePage({super.key});

  @override
  State<LocatePage> createState() => _LocatePageState();
}

class _LocatePageState extends State<LocatePage> {
  Stream<GuardianDevice?>? _deviceStream;
  final _refreshController = OnlineRefreshController();
  _LocateMode _mode = _LocateMode.current;
  _HistoryWindow _window = _HistoryWindow.hours24;
  DateTimeRange? _customRange;
  String? _selectedPointId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    _deviceStream ??= DashboardService().watchPrimaryDevice(uid);
    final split = AppLayout.isLocateSplit(MediaQuery.sizeOf(context).width);
    final subtitle = _mode == _LocateMode.current
        ? 'Última posição conhecida do aparelho'
        : 'Histórico de posições enviadas pelo app';

    return PremiumFeatureGate(
      featureName: 'Localizar',
      hasAccess: PremiumFeatures.locate,
      scaffoldTitle: 'Localizar',
      scaffoldSubtitle: subtitle,
      onRefresh: _refreshController.refresh,
      child: StreamBuilder<GuardianDevice?>(
        stream: _deviceStream,
        builder: (context, snapshot) {
          final initialLoad =
              snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData;

          return OnlineRefresh(
            controller: _refreshController,
            builder: (context, isRefreshing) {
              final body = initialLoad
                  ? const Center(child: CircularProgressIndicator())
                  : _LocateBody(
                      uid: uid,
                      device: snapshot.data,
                      split: split,
                      mode: _mode,
                      window: _window,
                      customRange: _customRange,
                      selectedPointId: _selectedPointId,
                      onModeChanged: (mode) => setState(() {
                        _mode = mode;
                        _selectedPointId = null;
                        if (mode == _LocateMode.current) {
                          _customRange = null;
                          if (_window == _HistoryWindow.custom) {
                            _window = _HistoryWindow.hours24;
                          }
                        }
                      }),
                      onWindowChanged: (window) => setState(() {
                        _window = window;
                        if (window != _HistoryWindow.custom) {
                          _customRange = null;
                        }
                        _selectedPointId = null;
                      }),
                      onCustomRangeChanged: (range) => setState(() {
                        _window = _HistoryWindow.custom;
                        _customRange = range;
                        _selectedPointId = null;
                      }),
                      onSelectPoint: (point) => setState(
                        () => _selectedPointId = point.id,
                      ),
                    );

              return GuardianScaffold(
                title: 'Localizar',
                subtitle: subtitle,
                onRefresh: _refreshController.refresh,
                fitViewport: split,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RefreshTickBar(
                      visible: isRefreshing && snapshot.hasData,
                    ),
                    if (split) Expanded(child: body) else body,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LocateBody extends StatelessWidget {
  const _LocateBody({
    required this.uid,
    required this.device,
    required this.split,
    required this.mode,
    required this.window,
    required this.customRange,
    required this.selectedPointId,
    required this.onModeChanged,
    required this.onWindowChanged,
    required this.onCustomRangeChanged,
    required this.onSelectPoint,
  });

  final String uid;
  final GuardianDevice? device;
  final bool split;
  final _LocateMode mode;
  final _HistoryWindow window;
  final DateTimeRange? customRange;
  final String? selectedPointId;
  final ValueChanged<_LocateMode> onModeChanged;
  final ValueChanged<_HistoryWindow> onWindowChanged;
  final ValueChanged<DateTimeRange> onCustomRangeChanged;
  final ValueChanged<LocationHistoryPoint> onSelectPoint;

  ({DateTime since, DateTime? until}) get _queryBounds {
    final now = DateTime.now();
    if (window == _HistoryWindow.custom && customRange != null) {
      final start = customRange!.start;
      final end = customRange!.end;
      return (
        since: DateTime(start.year, start.month, start.day),
        until: DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
      );
    }
    final duration = switch (window) {
      _HistoryWindow.hours24 => const Duration(hours: 24),
      _HistoryWindow.days7 => const Duration(days: 7),
      _HistoryWindow.days30 => const Duration(days: 30),
      _HistoryWindow.custom => const Duration(hours: 24),
    };
    return (since: now.subtract(duration), until: null);
  }

  @override
  Widget build(BuildContext context) {
    if (device == null) {
      return const _LocateEmpty(
        icon: Icons.smartphone_outlined,
        title: 'Nenhum aparelho sincronizado',
        message: 'Confirme o aparelho com o QR no Centro para '
            'enviar a primeira posição.',
      );
    }

    final status = device!.status;
    final current = status.location;
    final controls = _LocateControls(
      mode: mode,
      window: window,
      customRange: customRange,
      onModeChanged: onModeChanged,
      onWindowChanged: onWindowChanged,
      onCustomRangeChanged: onCustomRangeChanged,
    );

    if (mode == _LocateMode.current) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocationInfoCard(status: status),
          const SizedBox(height: 10),
          controls,
          const SizedBox(height: 12),
          if (current == null)
            const _LocateEmpty.noLocation()
          else if (split)
            Expanded(child: GuardianDeviceMap(location: current))
          else
            GuardianDeviceMap(location: current, height: 420),
        ],
      );
    }

    final bounds = _queryBounds;

    return StreamBuilder<List<LocationHistoryPoint>>(
      stream: LocationHistoryRepository().watchHistory(
        uid: uid,
        deviceId: device!.id,
        since: bounds.since,
        until: bounds.until,
      ),
      builder: (context, snap) {
        final points = snap.data ?? const <LocationHistoryPoint>[];
        final truncated =
            points.length >= LocationHistoryRepository.listenLimit;
        final clusters = groupLocationHistory(points);
        // Um vértice por local (mais recente do grupo), antigo → novo.
        final trail = [
          for (final c in clusters.reversed) c.representative,
        ];
        final selectedCluster = _resolveSelectedCluster(clusters);
        final selected = selectedCluster?.representative;
        final mapLocation = selected == null
            ? current
            : DeviceLocation(
                lat: selected.lat,
                lng: selected.lng,
                accuracyM: selected.accuracyM,
                updatedAt: selected.recordedAt,
                source: selected.source,
              );

        final historyList = LocationHistoryList(
          clusters: clusters,
          selectedId: selected?.id,
          onSelect: (cluster) => onSelectPoint(cluster.representative),
          maxHeight: split ? 200 : 240,
        );

        final focusCaption = selectedCluster == null
            ? null
            : [
                selectedCluster.timeRangeLabel(),
                ?selectedCluster.dwellLabel,
              ].join(' · ');

        final truncationNote = truncated
            ? const Padding(
                padding: EdgeInsets.only(top: 8),
                child: _HistoryLimitNote(),
              )
            : const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LocationInfoCard(
              status: status,
              focusLocation: selected == null ? null : mapLocation,
              focusCaption: focusCaption,
            ),
            const SizedBox(height: 10),
            controls,
            const SizedBox(height: 12),
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData)
              split
                  ? const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
            else if (mapLocation == null && clusters.isEmpty) ...[
              const _LocateEmpty.noLocation(),
              const SizedBox(height: 12),
              historyList,
              truncationNote,
            ] else if (mapLocation == null) ...[
              historyList,
              truncationNote,
            ] else if (split) ...[
              Expanded(
                child: GuardianDeviceMap(
                  location: mapLocation,
                  trail: trail,
                  selectedPointId: selected?.id,
                  onPointTap: onSelectPoint,
                ),
              ),
              const SizedBox(height: 12),
              historyList,
              truncationNote,
            ] else ...[
              GuardianDeviceMap(
                location: mapLocation,
                height: 360,
                trail: trail,
                selectedPointId: selected?.id,
                onPointTap: onSelectPoint,
              ),
              const SizedBox(height: 12),
              historyList,
              truncationNote,
            ],
          ],
        );
      },
    );
  }

  LocationHistoryCluster? _resolveSelectedCluster(
    List<LocationHistoryCluster> clusters,
  ) {
    if (clusters.isEmpty) return null;
    if (selectedPointId != null) {
      for (final c in clusters) {
        if (c.containsId(selectedPointId!)) return c;
      }
    }
    return clusters.first;
  }
}

class _LocateControls extends StatelessWidget {
  const _LocateControls({
    required this.mode,
    required this.window,
    required this.customRange,
    required this.onModeChanged,
    required this.onWindowChanged,
    required this.onCustomRangeChanged,
  });

  final _LocateMode mode;
  final _HistoryWindow window;
  final DateTimeRange? customRange;
  final ValueChanged<_LocateMode> onModeChanged;
  final ValueChanged<_HistoryWindow> onWindowChanged;
  final ValueChanged<DateTimeRange> onCustomRangeChanged;

  static final _rangeFmt = DateFormat('dd/MM/yy');

  static String _formatCustomRange(DateTimeRange range) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    if (start == end) return _rangeFmt.format(start);
    return '${_rangeFmt.format(start)} – ${_rangeFmt.format(end)}';
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day);
    final firstDate = lastDate.subtract(const Duration(days: 365));

    final initial = customRange ??
        DateTimeRange(
          start: lastDate.subtract(const Duration(days: 6)),
          end: lastDate,
        );

    try {
      final picked = await showEventDateRangePicker(
        context,
        firstDate: firstDate,
        lastDate: lastDate,
        initialRange: initial,
      );
      if (picked == null) return;
      onCustomRangeChanged(picked);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir o calendário: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GuardianFilterChip(
          label: 'Atual',
          icon: Icons.my_location,
          selected: mode == _LocateMode.current,
          onTap: () => onModeChanged(_LocateMode.current),
        ),
        GuardianFilterChip(
          label: 'Histórico',
          icon: Icons.route,
          selected: mode == _LocateMode.history,
          onTap: () => onModeChanged(_LocateMode.history),
        ),
        if (mode == _LocateMode.history) ...[
          GuardianFilterChip(
            label: '24 h',
            selected: window == _HistoryWindow.hours24,
            onTap: () => onWindowChanged(_HistoryWindow.hours24),
          ),
          GuardianFilterChip(
            label: '7 dias',
            selected: window == _HistoryWindow.days7,
            onTap: () => onWindowChanged(_HistoryWindow.days7),
          ),
          GuardianFilterChip(
            label: '30 dias',
            selected: window == _HistoryWindow.days30,
            onTap: () => onWindowChanged(_HistoryWindow.days30),
          ),
          GuardianFilterChip(
            label: customRange != null
                ? _formatCustomRange(customRange!)
                : 'Calendário',
            icon: Icons.calendar_month_rounded,
            selected: window == _HistoryWindow.custom,
            onTap: () => _pickCustomRange(context),
          ),
        ],
      ],
    );
  }
}

class _HistoryLimitNote extends StatelessWidget {
  const _HistoryLimitNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Mostrando os ${LocationHistoryRepository.listenLimit} pontos '
      'mais recentes deste período.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            height: 1.35,
          ),
    );
  }
}

/// Estado vazio no padrão de Dispositivos e Eventos.
class _LocateEmpty extends StatelessWidget {
  const _LocateEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  const _LocateEmpty.noLocation()
      : icon = Icons.location_off_outlined,
        title = 'Sem posição no momento',
        message = 'No celular, conceda a permissão de localização ao Guardian '
            'Sense e abra o app por alguns segundos.';

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
