import 'package:flutter/material.dart';
import 'package:guardian_portal/features/devices/presentation/widgets/device_pairing_card.dart';

class EmptyDevicesCard extends StatelessWidget {
  const EmptyDevicesCard({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return DevicePairingCard(uid: uid);
  }
}
