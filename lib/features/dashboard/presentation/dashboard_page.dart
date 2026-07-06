import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/features/dashboard/application/dashboard_service.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/empty_devices_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_checklist_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_setup_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_status_hero.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/quick_actions.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return GuardianScaffold(
      title: AppConstants.portalTitle,
      subtitle: 'Status do seu dispositivo',
      child: OnlineRefresh(
        builder: (context) => StreamBuilder(
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
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = ProtectionSnapshot.tone(status);
    final wide = MediaQuery.sizeOf(context).width >= 960;

    final hero = ProtectionStatusHero(status: status, tone: tone);
    final setup = ProtectionSetupCard(status: status);
    final checklist = ProtectionChecklistCard(status: status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: hero),
              const SizedBox(width: 20),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    setup,
                    const SizedBox(height: 14),
                    checklist,
                  ],
                ),
              ),
            ],
          )
        else ...[
          hero,
          const SizedBox(height: 20),
          setup,
          const SizedBox(height: 16),
          checklist,
        ],
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
