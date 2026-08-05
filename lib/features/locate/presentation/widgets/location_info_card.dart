import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/core/widgets/status_pill.dart';
import 'package:guardian_portal/features/dashboard/domain/device_location.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/locate/application/location_geocode_service.dart';
import 'package:guardian_portal/features/locate/domain/location_freshness.dart';

/// Resumo da última posição — mesmo idioma visual dos tiles de Dispositivos.
class LocationInfoCard extends StatefulWidget {
  const LocationInfoCard({super.key, required this.status});

  final DeviceStatus status;

  @override
  State<LocationInfoCard> createState() => _LocationInfoCardState();
}

class _LocationInfoCardState extends State<LocationInfoCard> {
  final _geocode = LocationGeocodeService();
  String? _address;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void didUpdateWidget(covariant LocationInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLoc = oldWidget.status.location;
    final newLoc = widget.status.location;
    if (oldLoc?.lat != newLoc?.lat || oldLoc?.lng != newLoc?.lng) {
      _loadAddress();
    }
  }

  Future<void> _loadAddress() async {
    final location = widget.status.location;
    if (location == null) {
      setState(() {
        _address = null;
        _loadingAddress = false;
      });
      return;
    }

    setState(() => _loadingAddress = true);
    final address = await _geocode.reverseGeocode(location.lat, location.lng);
    if (!mounted) return;
    setState(() {
      _address = address;
      _loadingAddress = false;
    });
  }

  Future<void> _copyCoordinates(DeviceLocation location) async {
    await Clipboard.setData(ClipboardData(text: _coordsOf(location)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coordenadas copiadas'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  static String _coordsOf(DeviceLocation location) =>
      '${location.lat.toStringAsFixed(5)}, ${location.lng.toStringAsFixed(5)}';

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final location = status.location;
    final stale =
        location != null && LocationFreshness.isStale(location.updatedAt);
    final staleMessage = location == null
        ? null
        : LocationFreshness.staleMessage(
            location.updatedAt,
            deviceOnline: status.isOnline,
          );

    final color = _toneColor(
      online: status.isOnline,
      hasLocation: location != null,
      stale: stale,
    );
    final statusLine = location == null
        ? 'SEM POSIÇÃO'
        : stale
            ? 'POSIÇÃO ANTIGA'
            : 'POSIÇÃO ATUAL';
    return SectionCard(
      padding: EdgeInsets.zero,
      // LayoutBuilder fora do IntrinsicHeight: um não mede o outro.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _sideBySideWidth;
          final header = _Header(
            status: status,
            location: location,
            color: color,
            statusLine: statusLine,
            showPill: !wide && constraints.maxWidth >= 520,
          );

          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: _body(
                        location: location,
                        staleMessage: staleMessage,
                        header: header,
                        wide: wide,
                        online: status.isOnline,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body({
    required DeviceLocation? location,
    required String? staleMessage,
    required Widget header,
    required bool wide,
    required bool online,
    required Color color,
  }) {
    if (location == null) return header;

    final address = _AddressRow(address: _address, loading: _loadingAddress);
    final coords = _CoordsRow(
      coords: _coordsOf(location),
      source: location.sourceLabel,
      onCopy: () => _copyCoordinates(location),
    );
    final stale =
        staleMessage == null ? null : _StaleRow(message: staleMessage);

    if (wide) {
      return _WideBody(
        header: header,
        address: address,
        coords: coords,
        stale: stale,
        pill: StatusPill(
          label: online ? 'ONLINE' : 'OFFLINE',
          color: color,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        Divider(height: 18, color: AppColors.divider.withValues(alpha: 0.9)),
        address,
        if (stale != null) ...[const SizedBox(height: 6), stale],
        const SizedBox(height: 8),
        coords,
      ],
    );
  }

  /// A partir daqui os três blocos cabem lado a lado sem quebrar.
  static const double _sideBySideWidth = 760;

  static Color _toneColor({
    required bool online,
    required bool hasLocation,
    required bool stale,
  }) {
    if (!online || !hasLocation) return AppColors.textMuted;
    return stale ? AppColors.riskElevated : AppColors.trustHigh;
  }
}

/// Distribui identificação, endereço e coordenadas em colunas.
class _WideBody extends StatelessWidget {
  const _WideBody({
    required this.header,
    required this.address,
    required this.coords,
    required this.stale,
    required this.pill,
  });

  final Widget header;
  final Widget address;
  final Widget coords;
  final Widget? stale;
  final Widget pill;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 4, child: header),
          const _ColumnDivider(),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                address,
                if (stale != null) ...[const SizedBox(height: 6), stale!],
              ],
            ),
          ),
          const _ColumnDivider(),
          Expanded(flex: 3, child: coords),
          const SizedBox(width: 12),
          pill,
        ],
      ),
    );
  }
}

class _ColumnDivider extends StatelessWidget {
  const _ColumnDivider();

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 24,
      thickness: 1,
      indent: 2,
      endIndent: 2,
      color: AppColors.divider.withValues(alpha: 0.9),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.status,
    required this.location,
    required this.color,
    required this.statusLine,
    required this.showPill,
  });

  final DeviceStatus status;
  final DeviceLocation? location;
  final Color color;
  final String statusLine;
  final bool showPill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textMuted,
    );

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(
            location == null ? Icons.location_off_outlined : Icons.place_outlined,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: status.isOnline ? 'Online' : 'Offline',
                      style: muted,
                    ),
                    TextSpan(text: '  ·  ', style: muted),
                    TextSpan(
                      text: statusLine,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                status.modelLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _metaLabel(location),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.25,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (showPill) ...[
          const SizedBox(width: 12),
          StatusPill(
            label: status.isOnline ? 'ONLINE' : 'OFFLINE',
            color: color,
          ),
        ],
      ],
    );
  }

  static String _metaLabel(DeviceLocation? location) {
    if (location == null) return 'Aguardando a primeira posição do aparelho';
    final parts = ['Atualizado ${formatRelativeTime(location.updatedAt)}'];
    if (location.accuracyM != null) parts.add(location.accuracyLabel);
    return parts.join(' · ');
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address, required this.loading});

  final String? address;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = loading
        ? 'Buscando endereço aproximado…'
        : address ?? 'Endereço aproximado indisponível';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.signpost_outlined,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: address != null && !loading
                ? theme.textTheme.bodySmall?.copyWith(height: 1.3)
                : theme.textTheme.bodySmall?.copyWith(
                    height: 1.3,
                    color: AppColors.textMuted,
                  ),
          ),
        ),
      ],
    );
  }
}

class _StaleRow extends StatelessWidget {
  const _StaleRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.schedule_outlined,
            size: 16,
            color: AppColors.riskElevated,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.riskElevated,
                  height: 1.3,
                ),
          ),
        ),
      ],
    );
  }
}

class _CoordsRow extends StatelessWidget {
  const _CoordsRow({
    required this.coords,
    required this.source,
    required this.onCopy,
  });

  final String coords;
  final String? source;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            [coords, ?source].join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Copiar coordenadas',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          onPressed: onCopy,
          icon: const Icon(Icons.copy_outlined, size: 16),
        ),
      ],
    );
  }
}
