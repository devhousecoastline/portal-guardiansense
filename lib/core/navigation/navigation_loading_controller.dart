import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Controla o overlay de loading ao trocar de rota pelo menu lateral.
class NavigationLoadingController extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> go(BuildContext context, String route) {
    return goWithRouter(GoRouter.of(context), route);
  }

  /// Navega com [GoRouter] já capturado — seguro após fechar o drawer mobile.
  Future<void> goWithRouter(GoRouter router, String route) async {
    if (_isLoading) return;

    final current = router.state.matchedLocation;
    if (current == route) return;

    _isLoading = true;
    notifyListeners();

    final started = DateTime.now();
    try {
      router.go(route);
      await WidgetsBinding.instance.endOfFrame;
      const minDisplay = Duration(milliseconds: 320);
      final elapsed = DateTime.now().difference(started);
      if (elapsed < minDisplay) {
        await Future<void>.delayed(minDisplay - elapsed);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class NavigationLoadingScope extends InheritedNotifier<NavigationLoadingController> {
  const NavigationLoadingScope({
    super.key,
    required NavigationLoadingController controller,
    required super.child,
  }) : super(notifier: controller);

  static NavigationLoadingController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NavigationLoadingScope>();
    assert(scope != null, 'NavigationLoadingScope não encontrado');
    return scope!.notifier!;
  }
}
