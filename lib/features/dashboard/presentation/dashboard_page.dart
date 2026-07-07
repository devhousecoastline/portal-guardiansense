import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
import 'package:guardian_portal/core/widgets/device_online_chip.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/features/dashboard/application/dashboard_service.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/empty_devices_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_checklist_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_setup_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_status_hero.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
        final device = snapshot.data;
        final initialLoad =
            snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

        return OnlineRefresh(
          controller: _refreshController,
          builder: (context, isRefreshing) {
            return GuardianScaffold(
              title: 'Centro',
              subtitle: 'Status do seu dispositivo',
              subtitleTrailing: device != null
                  ? DeviceOnlineChip(
                      isOnline: device.status.isOnline,
                      lastSeen: device.status.lastSeen,
                    )
                  : null,
              onRefresh: _refreshController.refresh,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RefreshTickBar(
                    visible: isRefreshing && snapshot.hasData,
                  ),
                  if (initialLoad)
                    const Center(child: CircularProgressIndicator())
                  else if (device == null)
                    const EmptyDevicesCard()
                  else
                    _DashboardBody(status: device.status),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = ProtectionSnapshot.tone(status);
    final wide = AppLayout.isDashboardRow(MediaQuery.sizeOf(context).width);

    final hero = ProtectionStatusHero(
      status: status,
      tone: tone,
      stretchVertically: wide,
    );
    final setup = ProtectionSetupCard(
      status: status,
      stretchVertically: wide,
    );
    final checklist = ProtectionChecklistCard(status: status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: hero),
                const SizedBox(width: 20),
                Expanded(flex: 6, child: setup),
              ],
            ),
          ),
          const SizedBox(height: 18),
          checklist,
        ]
        else ...[
          hero,
          const SizedBox(height: 20),
          setup,
          const SizedBox(height: 16),
          checklist,
        ],
        const SizedBox(height: 16),
        Text(
          ProtectionSnapshot.dashboardFooter(status),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}
