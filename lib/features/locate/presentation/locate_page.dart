import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/core/widgets/status_badge.dart';
import 'package:guardian_portal/features/dashboard/application/dashboard_service.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/locate/presentation/widgets/guardian_device_map.dart';

class LocatePage extends StatelessWidget {
  const LocatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return GuardianScaffold(
      title: 'Localizar',
      subtitle: 'Última posição conhecida do aparelho',
      child: OnlineRefresh(
        builder: (context) => StreamBuilder(
          stream: DashboardService().watchPrimaryDevice(uid),
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final device = snapshot.data;
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LocationInfoCard(status: status),
              const SizedBox(height: 16),
              if (location != null)
                GuardianDeviceMap(location: location)
              else
                const _NoLocationCard(),
              const SizedBox(height: 16),
              const _LocationHintCard(),
            ],
          );
        },
        ),
      ),
    );
  }
}

class _LocationInfoCard extends StatelessWidget {
  const _LocationInfoCard({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final location = status.location;
    final tone = status.isOnline ? StatusTone.protected : StatusTone.offline;

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
            Text(
              'Atualizado ${formatRelativeTime(location.updatedAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Precisão: ${location.accuracyLabel}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${location.lat.toStringAsFixed(5)}, ${location.lng.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
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
          const SizedBox(width: 12),
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
