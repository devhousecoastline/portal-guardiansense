import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    this.logoSize = 88,
    this.compact = false,
  });

  final double logoSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GuardianLogo(size: logoSize),
        SizedBox(height: compact ? 20 : 32),
        Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          AppConstants.portalTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.footerTagline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textMuted.withValues(alpha: 0.65),
              ),
        ),
      ],
    );
  }
}
