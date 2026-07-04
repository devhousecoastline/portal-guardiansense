import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';

/// Métricas de sincronização e estado do serviço nativo.
class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({super.key, required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          MetricRow(
            label: 'Runtime',
            value: _boolLabel(status.runtimeActive, active: 'Ativo', inactive: 'Inativo'),
            valueColor: status.runtimeActive == true
                ? AppColors.trustHigh
                : AppColors.textMuted,
          ),
          const Divider(height: 1),
          MetricRow(
            label: 'Escudo (Ostra)',
            value: status.oysterClosed == null
                ? '—'
                : status.oysterClosed!
                    ? 'Fechada'
                    : 'Aberta',
            valueColor: status.oysterClosed == true
                ? AppColors.trustHigh
                : AppColors.riskElevated,
          ),
          const Divider(height: 1),
          MetricRow(
            label: 'Última sincronização',
            value: formatRelativeTime(status.lastSeen),
          ),
          const Divider(height: 1),
          MetricRow(
            label: 'Último evento',
            value: status.lastEventSummary != null
                ? '${status.lastEventSummary!} · ${formatRelativeTime(status.lastEventAt)}'
                : formatRelativeTime(status.lastEventAt),
          ),
          if (status.batteryLevel != null) ...[
            const Divider(height: 1),
            MetricRow(
              label: 'Bateria',
              value: '${status.batteryLevel}%',
            ),
          ],
          const Divider(height: 1),
          MetricRow(
            label: 'Versão do app',
            value: status.appVersion,
          ),
        ],
      ),
    );
  }

  String _boolLabel(bool? value, {required String active, required String inactive}) {
    if (value == null) return '—';
    return value ? active : inactive;
  }
}
