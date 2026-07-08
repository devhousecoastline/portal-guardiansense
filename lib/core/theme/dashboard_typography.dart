import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

/// Escala tipográfica compartilhada pelos 4 cards do Centro.
abstract final class DashboardTypography {
  /// Título principal do card — ex.: "Configurações do aparelho".
  static TextStyle cardTitle(BuildContext context, {required bool compact}) {
    final base = compact
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleLarge;
    return base!.copyWith(fontWeight: FontWeight.w600);
  }

  /// Subtítulo abaixo do título (somente desktop).
  static TextStyle cardSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: AppColors.textMuted,
        );
  }

  /// Labels secundários — perguntas, chips, legendas.
  static TextStyle mutedLabel(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: AppColors.textMuted,
          height: 1.2,
        );
  }

  /// Valores em destaque — respostas, itens de checklist.
  static TextStyle emphasis(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          height: 1.25,
        );
  }

  /// Título dentro de painéis internos — ex.: "Fechar ostra remotamente".
  static TextStyle panelTitle(BuildContext context, {required Color color}) {
    return Theme.of(context).textTheme.titleSmall!.copyWith(color: color);
  }

  /// Texto de apoio em painéis internos.
  static TextStyle panelSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: AppColors.textMuted,
          height: 1.3,
        );
  }

  /// Destaque intermediário — faixa de progresso, seções.
  static TextStyle highlightCaption(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.titleSmall!.copyWith(
          color: color,
        );
  }

  /// Nome do dispositivo no hero.
  static TextStyle deviceName(BuildContext context, {required bool compact}) {
    return cardTitle(context, compact: compact);
  }
}
