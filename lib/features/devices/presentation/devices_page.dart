import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/devices/domain/device_registry.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';
import 'package:guardian_portal/features/devices/presentation/widgets/device_pairing_card.dart';
import 'package:guardian_portal/features/devices/presentation/widgets/device_plan_banner.dart';
import 'package:guardian_portal/features/devices/presentation/widgets/device_switches_card.dart';
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
              subtitle: 'Aparelho vinculado e histórico de trocas',
              onRefresh: _refreshController.refresh,
              fitViewport: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RefreshTickBar(visible: isRefreshing && snapshot.hasData),
                  Expanded(
                    child: initialLoad
                        ? const Center(child: CircularProgressIndicator())
                        : _DevicesBody(uid: uid, list: snapshot.data),
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

class _DevicesBody extends StatefulWidget {
  const _DevicesBody({required this.uid, required this.list});

  final String uid;
  final DeviceListSnapshot? list;

  @override
  State<_DevicesBody> createState() => _DevicesBodyState();
}

class _DevicesBodyState extends State<_DevicesBody> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
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

    final snapshot = list;
    if (!snapshot.hasActive && !snapshot.hasReleased) {
      return DevicePairingCard(uid: widget.uid);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeviceSwitchesCard(switches: snapshot.switches),
        DevicePlanBanner(snapshot: snapshot),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility:
                snapshot.visible.length + snapshot.released.length > 3,
            child: ListView(
              controller: _scrollController,
              primary: false,
              padding: const EdgeInsets.only(right: 14, bottom: 28),
              children: [
                if (snapshot.hasActive) ...[
                  _SectionLabel(
                    icon: Icons.link,
                    label: snapshot.visible.length == 1
                        ? 'Aparelho vinculado'
                        : 'Aparelhos vinculados',
                  ),
                  const SizedBox(height: 8),
                  ..._tileList(snapshot.visible),
                ] else ...[
                  DevicePairingCard(uid: widget.uid),
                ],
                if (snapshot.hasReleased) ...[
                  const SizedBox(height: 16),
                  _SectionLabel(
                    icon: Icons.history,
                    label: 'Histórico',
                  ),
                  const SizedBox(height: 8),
                  ..._tileList(snapshot.released),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _tileList(List<GuardianDevice> devices) {
    final widgets = <Widget>[];
    for (var i = 0; i < devices.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 10));
      widgets.add(DeviceTile(device: devices[i]));
    }
    return widgets;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
