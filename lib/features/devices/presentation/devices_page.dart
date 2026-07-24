import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RefreshTickBar(visible: isRefreshing && snapshot.hasData),
                  if (initialLoad)
                    const Center(child: CircularProgressIndicator())
                  else ..._buildContent(snapshot.data),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildContent(DeviceListSnapshot? list) {
    if (list == null) {
      return const [
        SectionCard(
          child: Text(
            'Não foi possível carregar os dispositivos.',
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    if (list.visible.isEmpty) {
      return const [
        SectionCard(
          child: Text(
            'Nenhum aparelho vinculado. Instale o Guardian Sense no celular, '
            'entre com a mesma conta e conclua o onboarding para sincronizar.',
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    return [
      DevicePlanBanner(snapshot: list),
      for (final device in list.visible) ...[
        DeviceTile(device: device),
        const SizedBox(height: 12),
      ],
    ];
  }
}
