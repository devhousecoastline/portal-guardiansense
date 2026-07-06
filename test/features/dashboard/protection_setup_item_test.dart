import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';

void main() {
  test('fromFirestoreList ignora entradas inválidas', () {
    final items = ProtectionSetupItem.fromFirestoreList([
      {'id': 'notifications', 'label': 'Notificações', 'done': true},
      {'id': 'battery'},
      'invalid',
      {'label': 'Sem id', 'done': false},
    ]);

    expect(items, hasLength(1));
    expect(items.first.id, 'notifications');
    expect(items.first.done, isTrue);
  });

  test('fromFirestoreList retorna vazio para tipos inesperados', () {
    expect(ProtectionSetupItem.fromFirestoreList(null), isEmpty);
    expect(ProtectionSetupItem.fromFirestoreList('x'), isEmpty);
  });
}
