import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/app/guardian_portal_app.dart';

void main() {
  testWidgets('Portal carrega', (tester) async {
    await tester.pumpWidget(const GuardianPortalApp());
    expect(find.text('Guardian Sense'), findsWidgets);
  });
}
