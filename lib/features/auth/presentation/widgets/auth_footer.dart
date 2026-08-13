import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    this.includeHorizontalPadding = true,
  });

  /// Desligar quando o pai já aplica padding horizontal (ex.: scroll do login).
  final bool includeHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final muted = AppColors.textMuted.withValues(alpha: 0.55);
    final versionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: narrow ? 12 : 13,
          color: muted,
          fontWeight: FontWeight.w500,
        );
    final copyright = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: narrow ? 13 : 15,
          color: muted,
        );
    final hPad = includeHorizontalPadding ? 24.0 : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        hPad,
        narrow ? 12 : 16,
        hPad,
        narrow ? 16 : 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Portal: v${AppConstants.portalVersion}',
            style: versionStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '© ${DateTime.now().year} ${AppConstants.appName} · '
            'Todos os direitos reservados.',
            style: copyright,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
