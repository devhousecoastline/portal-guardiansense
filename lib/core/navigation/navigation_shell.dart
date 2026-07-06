import 'package:flutter/material.dart';
import 'package:guardian_portal/core/navigation/navigation_loading_controller.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

/// Envolve as rotas autenticadas e exibe loading durante troca pelo drawer.
class NavigationShell extends StatelessWidget {
  const NavigationShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loading = NavigationLoadingScope.of(context);

    return ListenableBuilder(
      listenable: loading,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (loading.isLoading)
              Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: AppColors.background.withValues(alpha: 0.72),
                    child: const Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
