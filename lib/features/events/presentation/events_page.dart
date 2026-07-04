import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/events/data/events_repository.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';
import 'package:guardian_portal/features/events/presentation/widgets/event_tile.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return GuardianScaffold(
      title: 'Eventos',
      subtitle: 'Linha do tempo de segurança',
      child: StreamBuilder(
        stream: DeviceRepository().watchPrimaryDevice(uid),
        builder: (context, deviceSnap) {
          if (deviceSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final deviceId = deviceSnap.data?.id;
          return StreamBuilder<List<SecurityEvent>>(
            stream: EventsRepository().watchRecent(uid, deviceId: deviceId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return SectionCard(
                  child: Text(
                    'Não foi possível carregar eventos.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return const SectionCard(
                  child: Column(
                    children: [
                      Icon(Icons.timeline_outlined,
                          size: 40, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'Nenhum evento sincronizado ainda.\n'
                        'Quando o app enviar alertas à nuvem, eles aparecerão aqui.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (final event in events) ...[
                    EventTile(event: event),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
