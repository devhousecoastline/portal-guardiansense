import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/core/layout/dashboard_layout.dart';

void main() {
  group('DashboardLayoutSpec.resolve', () {
    test('mobile em largura estreita', () {
      final spec = DashboardLayoutSpec.resolve(
        viewportWidth: 800,
        viewportHeight: 900,
      );

      expect(spec.profile, DashboardLayoutProfile.mobile);
      expect(spec.useBottomRowSplit, isFalse);
      expect(spec.stretchTopRow, isFalse);
    });

    test('notebook em tela larga e baixa', () {
      final spec = DashboardLayoutSpec.resolve(
        viewportWidth: 1366,
        viewportHeight: 768,
      );

      expect(spec.profile, DashboardLayoutProfile.notebook);
      expect(spec.compact, isTrue);
      expect(spec.useBottomRowSplit, isTrue);
      expect(spec.bottomRowContainmentFlex, spec.bottomRowChecklistFlex);
      expect(spec.checklistTwoColumns, isFalse);
      expect(spec.checklistPairGrid, isTrue);
    });

    test('desktop em monitor alto', () {
      final spec = DashboardLayoutSpec.resolve(
        viewportWidth: 1440,
        viewportHeight: 1000,
      );

      expect(spec.profile, DashboardLayoutProfile.desktop);
      expect(spec.stretchTopRow, isTrue);
      expect(spec.useBottomRowSplit, isFalse);
      expect(spec.checklistTwoColumns, isTrue);
    });
  });
}
