import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/application/dashboard_service.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';
import 'package:guardian_portal/features/locate/presentation/widgets/guardian_device_map.dart';
import 'package:guardian_portal/features/locate/presentation/widgets/location_info_card.dart';

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
    final split = AppLayout.isLocateSplit(MediaQuery.sizeOf(context).width);

    return StreamBuilder<GuardianDevice?>(
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
                : _LocateBody(device: snapshot.data, split: split);

            return GuardianScaffold(
              title: 'Localizar',
              subtitle: 'Última posição conhecida do aparelho',
              onRefresh: _refreshController.refresh,
              // Só o split cabe sem rolagem; em coluna o mapa precisa de scroll.
              fitViewport: split,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RefreshTickBar(visible: isRefreshing && snapshot.hasData),
                  if (split) Expanded(child: body) else body,
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LocateBody extends StatelessWidget {
  const _LocateBody({required this.device, required this.split});

  final GuardianDevice? device;
  final bool split;

  @override
  Widget build(BuildContext context) {
    if (device == null) {
      return const _LocateEmpty(
        icon: Icons.smartphone_outlined,
        title: 'Nenhum aparelho sincronizado',
        message: 'Abra o Guardian Sense no celular com a mesma conta para '
            'enviar a primeira posição.',
      );
    }

    final status = device!.status;
    final location = status.location;
    final info = LocationInfoCard(status: status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        info,
        const SizedBox(height: 8),
        const _LocationFootnote(),
        const SizedBox(height: 12),
        if (location == null)
          const _LocateEmpty.noLocation()
        // Com viewport fixo o mapa fica com toda a altura restante.
        else if (split)
          Expanded(child: GuardianDeviceMap(location: location))
        else
          GuardianDeviceMap(location: location, height: 420),
      ],
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

/// Substitui o antigo card de dica — mesma informação em uma linha.
class _LocationFootnote extends StatelessWidget {
  const _LocationFootnote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'A posição é enviada enquanto o app está em uso. O envio contínuo '
            'em segundo plano chega em uma atualização futura.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ),
      ],
    );
  }
}
