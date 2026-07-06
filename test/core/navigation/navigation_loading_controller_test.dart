import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/core/navigation/navigation_loading_controller.dart';

void main() {
  test('isLoading inicia false', () {
    final controller = NavigationLoadingController();
    addTearDown(controller.dispose);
    expect(controller.isLoading, isFalse);
  });

  testWidgets('NavigationLoadingScope expõe o controller', (tester) async {
    final controller = NavigationLoadingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      NavigationLoadingScope(
        controller: controller,
        child: Builder(
          builder: (context) {
            expect(
              NavigationLoadingScope.of(context),
              same(controller),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
