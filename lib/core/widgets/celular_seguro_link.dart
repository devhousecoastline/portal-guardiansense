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
    final linkStyle = bodyStyle?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );

    return Material(
      color: AppColors.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: CelularSeguroLink.open,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
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
                  children: [
                    Text('Roubo ou furto?', style: titleStyle),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Bloqueie na operadora pelo ',
                            style: bodyStyle,
                          ),
                          TextSpan(
                            text: 'Celular Seguro',
                            style: linkStyle,
                          ),
                          TextSpan(text: ' (governo).', style: bodyStyle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: compact ? 14 : 16,
                color: AppColors.primary.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
