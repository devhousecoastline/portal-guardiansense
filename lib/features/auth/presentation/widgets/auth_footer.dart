import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          color: AppColors.textMuted.withValues(alpha: 0.7),
        );

    final copyright = muted?.copyWith(
      fontSize: 11,
      color: AppColors.textMuted.withValues(alpha: 0.5),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Text(AppConstants.appVersion, style: muted),
          const SizedBox(height: 8),
          Text(
            '© ${DateTime.now().year} ${AppConstants.copyrightHolder}. '
            'Todos os direitos reservados.',
            style: copyright,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
