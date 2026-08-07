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

  /// Altura alinhada ao banner "Todos os requisitos…" do card de setup.
  static double minHeight({required bool compact}) => compact ? 56.0 : 64.0;

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

    final radius = BorderRadius.circular(10);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight(compact: compact)),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: radius,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: CelularSeguroLink.open,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 8 : 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Roubo ou furto?', style: titleStyle),
                      const SizedBox(height: 2),
                      Text(
                        compact
                            ? 'Bloqueie IMEI/linha pelo programa do governo.'
                            : 'Bloqueie IMEI/linha na operadora pelo programa '
                                'do governo.',
                        style: bodyStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
