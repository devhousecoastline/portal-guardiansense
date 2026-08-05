import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/dashboard/domain/device_location.dart';
import 'package:latlong2/latlong.dart';

/// Mapa Guardian Sense (Carto Voyager — legível no tema escuro do portal).
class GuardianDeviceMap extends StatefulWidget {
  const GuardianDeviceMap({
    super.key,
    required this.location,
    this.height,
  });

  final DeviceLocation location;

  /// Null preenche a altura disponível — usado no split com viewport fixo.
  final double? height;

  @override
  State<GuardianDeviceMap> createState() => _GuardianDeviceMapState();
}

double _accuracyRadiusM(double? accuracyM) {
  final m = accuracyM ?? 50;
  return m.clamp(15, 500);
}

class _GuardianDeviceMapState extends State<GuardianDeviceMap> {
  late final MapController _controller = MapController();

  LatLng get _point => LatLng(widget.location.lat, widget.location.lng);

  @override
  void didUpdateWidget(covariant GuardianDeviceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.location;
    final now = widget.location;
    if (old.lat != now.lat || old.lng != now.lng) {
      _controller.move(_point, _controller.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: _point,
                initialZoom: 15,
                minZoom: 4,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains:  ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'guardian_portal',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _point,
                      radius: _accuracyRadiusM(widget.location.accuracyM),
                      useRadiusInMeter: true,
                      color: AppColors.trustHigh.withValues(alpha: 0.12),
                      borderColor: AppColors.trustHigh.withValues(alpha: 0.35),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _point,
                      width: 56,
                      height: 56,
                      alignment: Alignment.topCenter,
                      child: const _ShieldPin(),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap · CARTO',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Material(
                color: AppColors.card.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                       EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'Círculo: margem de precisão GPS',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: AppColors.card.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                child: IconButton(
                  tooltip: 'Centralizar',
                  onPressed: () => _controller.move(_point, 15),
                  icon:  Icon(
                    Icons.my_location,
                    color: AppColors.trustHigh,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ShieldPin extends StatelessWidget {
  const _ShieldPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.trustHigh, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.trustHigh.withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          ),
          padding:  EdgeInsets.all(6),
          child: Image.asset(
            'assets/images/shield_transparent.png',
            fit: BoxFit.contain,
          ),
        ),
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.trustHigh,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
