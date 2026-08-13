import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final copyright = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: narrow ? 13 : 15,
          color: AppColors.textMuted.withValues(alpha: 0.55),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(24, narrow ? 12 : 16, 24, narrow ? 16 : 24),
      child: Text(
        '© ${DateTime.now().year} ${AppConstants.appName} · '
        'Todos os direitos reservados.',
        style: copyright,
        textAlign: TextAlign.center,
      ),
    );
  }
}
