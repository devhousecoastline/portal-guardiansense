import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/status_badge.dart';
import 'package:guardian_portal/features/dashboard/application/dashboard_service.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/empty_devices_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_hero_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/quick_actions.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/sync_status_row.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return GuardianScaffold(
      title: AppConstants.portalTitle,
      subtitle: 'Status do seu dispositivo',
      child: StreamBuilder(
        stream: DashboardService().watchPrimaryDevice(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final device = snapshot.data;
          if (device == null) return const EmptyDevicesCard();

          return _DashboardBody(status: device.status);
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status.level) {
      ProtectionLevel.protected => StatusTone.protected,
      ProtectionLevel.partial => StatusTone.warning,
      ProtectionLevel.alert => StatusTone.critical,
      ProtectionLevel.offline => StatusTone.offline,
      ProtectionLevel.unknown => StatusTone.neutral,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProtectionHeroCard(status: status, tone: tone),
        const SizedBox(height: 20),
        SyncStatusCard(status: status),
        const SizedBox(height: 20),
        const DashboardQuickActions(),
        const SizedBox(height: 16),
        Text(
          'O celular detecta, decide e bloqueia. O portal apenas reflete o que foi sincronizado.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}
