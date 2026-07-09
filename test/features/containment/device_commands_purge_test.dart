import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/containment/data/device_commands_purge.dart';
import 'package:guardian_portal/features/containment/domain/device_command.dart';

void main() {
  group('DeviceCommandsPurge.isEligibleForDeletion', () {
    final cutoff = DateTime(2026, 1, 1);

    test('remove applied antigo', () {
      expect(
        DeviceCommandsPurge.isEligibleForDeletion(
          {
            'status': DeviceCommandStatus.applied.storageKey,
            'createdAt': DateTime(2025, 12, 1),
          },
          cutoff,
        ),
        isTrue,
      );
    });

    test('mantém pending mesmo antigo', () {
      expect(
        DeviceCommandsPurge.isEligibleForDeletion(
          {
            'status': DeviceCommandStatus.pending.storageKey,
            'createdAt': DateTime(2025, 12, 1),
          },
          cutoff,
        ),
        isFalse,
      );
    });

    test('mantém applied recente', () {
      expect(
        DeviceCommandsPurge.isEligibleForDeletion(
          {
            'status': DeviceCommandStatus.applied.storageKey,
            'createdAt': DateTime(2026, 1, 15),
          },
          cutoff,
        ),
        isFalse,
      );
    });
  });
}
