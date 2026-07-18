import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/core/widgets/status_badge.dart';
import 'package:guardian_portal/features/dashboard/application/dashboard_service.dart';
import 'package:guardian_portal/features/dashboard/domain/device_location.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';
import 'package:guardian_portal/features/locate/application/location_geocode_service.dart';
import 'package:guardian_portal/features/locate/domain/location_freshness.dart';
import 'package:guardian_portal/features/locate/presentation/widgets/guardian_device_map.dart';

class LocatePage extends StatefulWidget {
  const LocatePage({super.key});

  @override
  State<LocatePage> createState() => _LocatePageState();
}

class _LocatePageState extends State<LocatePage> {
  Stream<GuardianDevice?>? _deviceStream;
  final _refreshController = OnlineRefreshController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    _deviceStream ??= DashboardService().watchPrimaryDevice(uid);

    return StreamBuilder<GuardianDevice?>(
      stream: _deviceStream,
      builder: (context, snapshot) {
        final initialLoad =
            snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

        return OnlineRefresh(
          controller: _refreshController,
          builder: (context, isRefreshing) {
            return GuardianScaffold(
              title: 'Localizar',
              subtitle: 'Última posição conhecida do aparelho',
              onRefresh: _refreshController.refresh,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RefreshTickBar(visible: isRefreshing && snapshot.hasData),
                  if (initialLoad)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildLocateBody(context, snapshot.data),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLocateBody(BuildContext context, GuardianDevice? device) {
    if (device == null) {
      return const SectionCard(
        child: Text(
          'Nenhum dispositivo sincronizado ainda.\n'
          'Abra o app Guardian Sense no celular com a mesma conta.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final status = device.status;
    final location = status.location;
    final staleMessage = location != null
        ? LocationFreshness.staleMessage(
            location.updatedAt,
            deviceOnline: status.isOnline,
          )
        : null;
    final split = AppLayout.isLocateSplit(MediaQuery.sizeOf(context).width);
    final mapHeight = split ? 520.0 : 420.0;

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LocationInfoCard(status: status),
        if (staleMessage != null) ...[
          const SizedBox(height: 12),
          _StaleLocationBanner(message: staleMessage),
        ],
        if (!split) ...[
          const SizedBox(height: 16),
          if (location != null)
            GuardianDeviceMap(location: location, height: mapHeight)
          else
            const _NoLocationCard(),
        ],
        if (!split) ...[
          const SizedBox(height: 16),
          const _LocationHintCard(),
        ],
      ],
    );

    final mapSection = location != null
        ? GuardianDeviceMap(location: location, height: mapHeight)
        : const _NoLocationCard();

    if (split) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: infoColumn),
                const SizedBox(width: 20),
                Expanded(flex: 6, child: mapSection),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _LocationHintCard(),
        ],
      );
    }

    return infoColumn;
  }
}

class _LocationInfoCard extends StatefulWidget {
  const _LocationInfoCard({required this.status});

  final DeviceStatus status;

  @override
  State<_LocationInfoCard> createState() => _LocationInfoCardState();
}

class _LocationInfoCardState extends State<_LocationInfoCard> {
  final _geocode = LocationGeocodeService();
  String? _address;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void didUpdateWidget(covariant _LocationInfoCard oldWidget) {
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
    final text =
        '${location.lat.toStringAsFixed(5)}, ${location.lng.toStringAsFixed(5)}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coordenadas copiadas'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final location = status.location;
    final tone = status.isOnline ? StatusTone.protected : StatusTone.offline;
    final bodyMuted = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textMuted,
        );
    final coordsStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  status.modelLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusBadge(
                label: status.isOnline ? 'ONLINE' : 'OFFLINE',
                tone: tone,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (location != null) ...[
            if (_loadingAddress)
              Text('Buscando endereço aproximado…', style: bodyMuted)
            else if (_address != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _address!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Atualizado ${formatRelativeTime(location.updatedAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Precisão: ${location.accuracyLabel}',
              style: bodyMuted,
            ),
            if (location.sourceLabel != null) ...[
              const SizedBox(height: 4),
              Text(location.sourceLabel!, style: bodyMuted),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${location.lat.toStringAsFixed(5)}, ${location.lng.toStringAsFixed(5)}',
                    style: coordsStyle,
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar coordenadas',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _copyCoordinates(location),
                  icon: const Icon(Icons.copy_outlined, size: 18),
                ),
              ],
            ),
          ] else
            Text(
              'Aguardando primeira localização do aparelho.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _StaleLocationBanner extends StatelessWidget {
  const _StaleLocationBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.riskElevated.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding:  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 20,
              color: AppColors.riskElevated,
            ),
             SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.riskElevated,
                      height: 1.4,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoLocationCard extends StatelessWidget {
  const _NoLocationCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'Sem posição no momento',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'No celular: conceda localização ao Guardian Sense e abra o app '
            'por alguns segundos para enviar a posição.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LocationHintCard extends StatelessWidget {
  const _LocationHintCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
           SizedBox(width: 12),
          Expanded(
            child: Text(
              'A posição é enviada enquanto o app está em uso (permissão '
              '"durante o uso"). Para rastreamento contínuo em segundo plano, '
              'uma atualização futura solicitará permissão adicional.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
