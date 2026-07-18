import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_palette.dart';

/// Cores do portal — leem a paleta ativa ([AppColorScope]).
abstract final class AppColors {
  static Color get background => _p.background;
  static Color get loginBackgroundCenter => _p.loginBackgroundCenter;
  static Color get loginBackgroundMid => _p.loginBackgroundMid;
  static Color get loginBackgroundEdge => _p.loginBackgroundEdge;
  static Color get surface => _p.surface;
  static Color get card => _p.card;
  static Color get primary => _p.primary;
  static Color get trustHigh => _p.trustHigh;
  static Color get trustMedium => _p.trustMedium;
  static Color get riskElevated => _p.riskElevated;
  static Color get riskCritical => _p.riskCritical;
  static Color get textPrimary => _p.textPrimary;
  static Color get textMuted => _p.textMuted;
  static Color get divider => _p.divider;

  static AppPalette get _p => AppColorScope.current;
}
