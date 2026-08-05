import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/devices/domain/device_registry.dart';
import 'package:guardian_portal/features/devices/presentation/widgets/device_plan_banner.dart';
import 'package:guardian_portal/features/devices/presentation/widgets/device_tile.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  Stream<DeviceListSnapshot>? _deviceListStream;
  final _refreshController = OnlineRefreshController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    _deviceListStream ??= DeviceRepository().watchDeviceList(uid);

    return StreamBuilder<DeviceListSnapshot>(
      stream: _deviceListStream,
      builder: (context, snapshot) {
        final initialLoad =
            snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

        return OnlineRefresh(
          controller: _refreshController,
          builder: (context, isRefreshing) {
            return GuardianScaffold(
              title: 'Dispositivos',
              subtitle: 'Aparelhos vinculados à sua conta',
              onRefresh: _refreshController.refresh,
              fitViewport: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RefreshTickBar(visible: isRefreshing && snapshot.hasData),
                  Expanded(
                    child: initialLoad
                        ? const Center(child: CircularProgressIndicator())
                        : _DevicesBody(list: snapshot.data),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DevicesBody extends StatelessWidget {
  const _DevicesBody({required this.list});

  final DeviceListSnapshot? list;

  @override
  Widget build(BuildContext context) {
    if (list == null) {
      return SectionCard(
        child: Text(
          'Não foi possível carregar os dispositivos.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }

    if (list!.visible.isEmpty) {
      return SectionCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smartphone_outlined,
              size: 36,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum aparelho vinculado',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Instale o Guardian Sense no celular, entre com a mesma conta '
              'e conclua o onboarding para sincronizar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      );
    }

    final devices = list!.visible;
    final count = devices.length;
    final countLabel =
        '$count ${count == 1 ? 'aparelho' : 'aparelhos'} neste portal';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DevicePlanBanner(snapshot: list!),
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
            thumbVisibility: devices.length > 4,
            child: ListView.separated(
              padding: const EdgeInsets.only(right: 14, bottom: 28),
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return DeviceTile(device: devices[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
