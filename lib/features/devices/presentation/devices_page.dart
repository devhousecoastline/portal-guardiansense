import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';
import 'package:guardian_portal/features/devices/presentation/widgets/device_tile.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return GuardianScaffold(
      title: 'Dispositivos',
      subtitle: 'Todos os aparelhos vinculados à sua conta',
      child: StreamBuilder<List<GuardianDevice>>(
        stream: DeviceRepository().watchDevices(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data ?? [];
          if (devices.isEmpty) {
            return const SectionCard(
              child: Text(
                'Nenhum dispositivo encontrado. Faça login no app mobile com esta conta.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return Column(
            children: [
              for (final device in devices) ...[
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
