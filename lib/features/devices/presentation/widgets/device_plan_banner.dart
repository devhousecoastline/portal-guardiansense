import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
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
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppColors.trustMedium, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plano ${snapshot.plan.isFree ? 'gratuito' : snapshot.plan.plan}: '
                    '$limit aparelho${limit == 1 ? '' : 's'} no portal. '
                    'Há $hidden aparelho${hidden == 1 ? '' : 's'} adicional'
                    '${hidden == 1 ? '' : 'is'} vinculado'
                    '${hidden == 1 ? '' : 's'} à conta.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => context.go(AppRoutes.premium),
                    borderRadius: BorderRadius.circular(6),
                    child: Text(
                      'Fazer upgrade para ver todos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
