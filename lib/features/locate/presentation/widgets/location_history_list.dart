import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/locate/application/location_geocode_service.dart';
import 'package:guardian_portal/features/locate/domain/location_history_cluster.dart';

/// Lista compacta dos locais da trilha (grupos por proximidade).
class LocationHistoryList extends StatefulWidget {
  const LocationHistoryList({
    super.key,
    required this.clusters,
    required this.selectedId,
    required this.onSelect,
    this.maxHeight = 220,
    this._geocode,
  });

  final List<LocationHistoryCluster> clusters;
  final String? selectedId;
  final ValueChanged<LocationHistoryCluster> onSelect;
  final double maxHeight;
  final LocationGeocodeService? _geocode;

  @override
  State<LocationHistoryList> createState() => _LocationHistoryListState();
}

class _LocationHistoryListState extends State<LocationHistoryList> {
  late final LocationGeocodeService _geocode =
      widget._geocode ?? LocationGeocodeService();

  /// Chave = lat,lng arredondados (mesmo cache do serviço).
  final Map<String, String?> _addresses = {};
  int _loadGen = 0;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void didUpdateWidget(covariant LocationHistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameRepresentatives(oldWidget.clusters, widget.clusters)) {
      _loadAddresses();
    }
  }

  bool _sameRepresentatives(
    List<LocationHistoryCluster> a,
    List<LocationHistoryCluster> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].representative.id != b[i].representative.id) return false;
    }
    return true;
  }

  String _cacheKey(double lat, double lng) =>
      '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  Future<void> _loadAddresses() async {
    final gen = ++_loadGen;
    for (final cluster in widget.clusters) {
      if (!mounted || gen != _loadGen) return;
      final p = cluster.representative;
      final key = _cacheKey(p.lat, p.lng);
      if (_addresses.containsKey(key)) continue;
      final address = await _geocode.reverseGeocode(p.lat, p.lng);
      if (!mounted || gen != _loadGen) return;
      setState(() => _addresses[key] = address);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clusters.isEmpty) {
      return SectionCard(
        child: Text(
          'Ainda não há pontos neste período. Ligue o GPS no celular '
          '(com o escudo ativo) para começar a trilha.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.35,
              ),
        ),
      );
    }

    return SectionCard(
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: widget.clusters.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: AppColors.divider.withValues(alpha: 0.8),
          ),
          itemBuilder: (context, index) {
            final cluster = widget.clusters[index];
            final point = cluster.representative;
            final selected = cluster.containsId(widget.selectedId ?? '');
            final key = _cacheKey(point.lat, point.lng);
            final address = _addresses[key];
            final coords =
                '${point.lat.toStringAsFixed(5)}, ${point.lng.toStringAsFixed(5)}';
            final title = (address != null && address.isNotEmpty)
                ? address
                : coords;
            final meta = [
              cluster.timeRangeLabel(),
              ?cluster.dwellLabel,
              formatRelativeTime(point.recordedAt),
              ?cluster.sourceLabel,
            ].join(' · ');

            return Material(
              color: selected
                  ? AppColors.trustHigh.withValues(alpha: 0.08)
                  : AppColors.card,
              child: InkWell(
                onTap: () => widget.onSelect(cluster),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        cluster.isStationary
                            ? Icons.hourglass_bottom_outlined
                            : Icons.place_outlined,
                        size: 20,
                        color: selected
                            ? AppColors.trustHigh
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                            if (address != null && address.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                coords,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textMuted
                                          .withValues(alpha: 0.85),
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
