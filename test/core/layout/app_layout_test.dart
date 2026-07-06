import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';

void main() {
  group('AppLayout.contentMaxWidth', () {
    test('mobile usa quase toda a largura', () {
      expect(AppLayout.contentMaxWidth(390), closeTo(342, 1));
    });

    test('desktop médio expande além de 960px', () {
      final main = 1680 - AppLayout.sideNavWidth;
      expect(AppLayout.contentMaxWidth(main), 1200);
    });

    test('ultrawide limita em 1520', () {
      final main = 2560 - AppLayout.sideNavWidth;
      expect(AppLayout.contentMaxWidth(main), 1520);
    });
  });
}
