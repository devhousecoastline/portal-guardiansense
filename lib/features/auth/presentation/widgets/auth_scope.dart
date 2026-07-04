import 'package:flutter/material.dart';
import 'package:guardian_portal/features/auth/application/auth_controller.dart';

class AuthScope extends InheritedWidget {
  const AuthScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final AuthController controller;

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope não encontrado');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) =>
      controller != oldWidget.controller;
}
