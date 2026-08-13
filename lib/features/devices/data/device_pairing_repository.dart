import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:guardian_portal/features/devices/domain/device_pairing.dart';

/// Lê desafios de QR e pede geração à callable `createDevicePairing`.
class DevicePairingRepository {
  DevicePairingRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('devicePairings');

  Stream<DevicePairing?> watchLatest(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .limit(8)
        .snapshots()
        .map((snap) {
      final now = DateTime.now().toUtc();
      final all = snap.docs
          .map((doc) => DevicePairing.fromMap(doc.id, doc.data()))
          .toList();
      for (final pairing in all) {
        if (pairing.isActiveAt(now)) return pairing;
      }
      return all.isEmpty ? null : all.first;
    });
  }

  Future<DevicePairing> create({bool refresh = false}) async {
    final callable = _functions.httpsCallable('createDevicePairing');
    final result = await callable.call({'refresh': refresh});
    final raw = result.data;
    if (raw is! Map) {
      throw StateError('Resposta inválida ao gerar o QR.');
    }
    return DevicePairing.fromCallable(Map<String, dynamic>.from(raw));
  }

  /// Debug/QA: `verified: false` nos aparelhos ativos (só Admin SDK).
  Future<int> resetVerification() async {
    final callable = _functions.httpsCallable('resetDeviceVerification');
    final result = await callable.call();
    final raw = result.data;
    if (raw is! Map) return 0;
    return (raw['reset'] as num?)?.toInt() ?? 0;
  }
}
