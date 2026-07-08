import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Link externo para o [Programa Celular Seguro](https://celularseguro.mj.gov.br/).
class CelularSeguroLink extends StatelessWidget {
  const CelularSeguroLink({
    super.key,
    this.compact = false,
    this.align = TextAlign.center,
  });

  final bool compact;
  final TextAlign align;

  static final _uri = Uri.parse(AppConstants.celularSeguroUrl);

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          fontSize: compact ? 11 : null,
          height: 1.35,
        );
    final link = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 11 : null,
          height: 1.35,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary.withValues(alpha: 0.45),
        );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Roubo ou furto? Bloqueio na operadora pelo ',
            style: muted,
          ),
          TextSpan(
            text: 'Celular Seguro',
            style: link,
            recognizer: TapGestureRecognizer()..onTap = _open,
          ),
          TextSpan(text: ' (governo).', style: muted),
        ],
      ),
      textAlign: align,
    );
  }

  Future<void> _open() async {
    await launchUrl(_uri, mode: LaunchMode.externalApplication);
  }
}
