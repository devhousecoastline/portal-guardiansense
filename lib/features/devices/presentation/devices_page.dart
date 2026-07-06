import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/devices/presentation/widgets/device_plan_banner.dart';
import 'package:guardian_portal/features/devices/presentation/widgets/device_tile.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return GuardianScaffold(
      title: 'Dispositivos',
      subtitle: 'Aparelhos vinculados à sua conta',
      child: StreamBuilder(
        stream: DeviceRepository().watchDeviceList(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data;
          if (list == null) {
            return const SectionCard(
              child: Text(
                'Não foi possível carregar os dispositivos.',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (list.visible.isEmpty) {
            return const SectionCard(
              child: Text(
                'Nenhum dispositivo encontrado. Faça login no app mobile com esta conta.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return Column(
            children: [
              DevicePlanBanner(snapshot: list),
              for (final device in list.visible) ...[
                DeviceTile(device: device),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}
