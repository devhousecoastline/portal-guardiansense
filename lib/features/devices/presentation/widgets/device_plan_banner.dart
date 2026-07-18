import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/devices/domain/device_registry.dart';

class DevicePlanBanner extends StatelessWidget {
  const DevicePlanBanner({super.key, required this.snapshot});

  final DeviceListSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.isOverLimit) return const SizedBox.shrink();

    final hidden = snapshot.hiddenCount;
    final limit = snapshot.plan.deviceLimit;

    return Padding(
      padding:  EdgeInsets.only(bottom: 16),
      child: SectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Icon(Icons.info_outline, color: AppColors.trustMedium, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Plano ${snapshot.plan.isFree ? 'gratuito' : snapshot.plan.plan}: '
                '$limit aparelho${limit == 1 ? '' : 's'} no portal. '
                'Há $hidden aparelho${hidden == 1 ? '' : 's'} adicional'
                '${hidden == 1 ? '' : 'is'} vinculado'
                '${hidden == 1 ? '' : 's'} à conta — faça upgrade para ver todos.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
