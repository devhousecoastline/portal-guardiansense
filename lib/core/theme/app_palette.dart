import 'package:flutter/material.dart';

/// Cores semânticas do portal (variante clara ou escura).
///
/// Alinhado ao app mobile ([AppPalette] do Guardian Sense).
final class AppPalette {
  const AppPalette({
    required this.background,
    required this.loginBackgroundCenter,
    required this.loginBackgroundMid,
    required this.loginBackgroundEdge,
    required this.surface,
    required this.card,
    required this.primary,
    required this.trustHigh,
    required this.trustMedium,
    required this.riskElevated,
    required this.riskCritical,
    required this.textPrimary,
    required this.textMuted,
    required this.divider,
  });

  final Color background;
  final Color loginBackgroundCenter;
  final Color loginBackgroundMid;
  final Color loginBackgroundEdge;
  final Color surface;
  final Color card;
  final Color primary;
  final Color trustHigh;
  final Color trustMedium;
  final Color riskElevated;
  final Color riskCritical;
  final Color textPrimary;
  final Color textMuted;
  final Color divider;

  static const dark = AppPalette(
    background: Color(0xFF0B0F14),
    loginBackgroundCenter: Color(0xFF162028),
    loginBackgroundMid: Color(0xFF0E141B),
    loginBackgroundEdge: Color(0xFF070A0E),
    surface: Color(0xFF141A22),
    card: Color(0xFF161B22),
    primary: Color(0xFF3D8BFF),
    trustHigh: Color(0xFF2ECC71),
    trustMedium: Color(0xFFF1C40F),
    riskElevated: Color(0xFFE67E22),
    riskCritical: Color(0xFFE74C3C),
    textPrimary: Color(0xFFF4F7FB),
    textMuted: Color(0xFF8B98A8),
    divider: Color(0xFF2A3441),
  );

  static const light = AppPalette(
    background: Color(0xFFF4F7FB),
    loginBackgroundCenter: Color(0xFFFFFFFF),
    loginBackgroundMid: Color(0xFFF4F7FB),
    loginBackgroundEdge: Color(0xFFE8EEF5),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF2563EB),
    trustHigh: Color(0xFF16A34A),
    trustMedium: Color(0xFFCA8A04),
    riskElevated: Color(0xFFEA580C),
    riskCritical: Color(0xFFDC2626),
    textPrimary: Color(0xFF0F172A),
    textMuted: Color(0xFF64748B),
    divider: Color(0xFFE2E8F0),
  );
}

/// Paleta ativa — atualizada ao trocar o tema.
abstract final class AppColorScope {
  static AppPalette current = AppPalette.dark;
}
