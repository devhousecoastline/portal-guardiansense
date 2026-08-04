import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_link_chip.dart';
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

  static Future<void> open() => launchUrl(_uri, mode: LaunchMode.externalApplication);

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
            recognizer: TapGestureRecognizer()..onTap = open,
          ),
          TextSpan(text: ' (governo).', style: muted),
        ],
      ),
      textAlign: align,
    );
  }
}

/// Destaque clicável para uso dentro do card de contenção (ostra fechada).
class CelularSeguroCallout extends StatelessWidget {
  const CelularSeguroCallout({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: compact ? 12 : 13,
        );
    final bodyStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          fontSize: compact ? 11 : 12,
          height: 1.35,
        );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.phonelink_lock_rounded,
            size: compact ? 18 : 20,
            color: AppColors.primary,
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Roubo ou furto?', style: titleStyle),
                SizedBox(height: compact ? 2 : 2),
                Text(
                  compact
                      ? 'Bloqueie IMEI/linha pelo programa do governo.'
                      : 'Bloqueie IMEI/linha na operadora pelo programa do governo.',
                  style: bodyStyle,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: compact ? 6 : 10),
                GuardianLinkChip(
                  label: 'Abrir Celular Seguro',
                  onPressed: CelularSeguroLink.open,
                  compact: true,
                  external: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
