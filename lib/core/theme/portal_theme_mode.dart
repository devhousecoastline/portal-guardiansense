import 'package:flutter/material.dart';

/// Tema visual do portal (persistido em preferências).
enum PortalThemeMode {
  dark,
  light;

  String get label => switch (this) {
        PortalThemeMode.dark => 'Escuro',
        PortalThemeMode.light => 'Claro',
      };

  String get description => switch (this) {
        PortalThemeMode.dark => 'Fundo escuro',
        PortalThemeMode.light => 'Fundo claro — melhor ao sol',
      };

  ThemeMode get materialThemeMode => switch (this) {
        PortalThemeMode.dark => ThemeMode.dark,
        PortalThemeMode.light => ThemeMode.light,
      };

  IconData get icon => switch (this) {
        PortalThemeMode.dark => Icons.dark_mode_outlined,
        PortalThemeMode.light => Icons.light_mode_outlined,
      };

  /// Padrão do portal: escuro (já era o único modo).
  static PortalThemeMode fromStorage(String? raw) {
    if (raw == PortalThemeMode.light.name) return PortalThemeMode.light;
    if (raw == PortalThemeMode.dark.name) return PortalThemeMode.dark;
    return PortalThemeMode.dark;
  }
}
