import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/theme_controller.dart';

/// Expõe [ThemeController] na árvore (Configurações, MaterialApp).
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope não encontrado');
    return scope!.notifier!;
  }
}
