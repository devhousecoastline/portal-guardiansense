import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/subscription/domain/subscription_entitlement.dart';

class SubscriptionRepository {
  SubscriptionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  Stream<SubscriptionEntitlement?> watchEntitlement(String uid) {
    return _userRef(uid).snapshots().map((doc) {
      final raw = doc.data()?['subscription'];
      if (raw is! Map) return null;
      return fromFirestoreMap(Map<String, dynamic>.from(raw));
    });
  }

  Future<SubscriptionEntitlement?> getEntitlement(String uid) async {
    final doc = await _userRef(uid).get();
    final raw = doc.data()?['subscription'];
    if (raw is! Map) return null;
    return fromFirestoreMap(Map<String, dynamic>.from(raw));
  }

  /// Garante trial na primeira leitura (política legado generosa do contrato).
  Future<SubscriptionEntitlement> ensureTrial(String uid) async {
    final ref = _userRef(uid);
    final snap = await ref.get();
    final raw = snap.data()?['subscription'];
    if (raw is Map) {
      final existing = fromFirestoreMap(Map<String, dynamic>.from(raw));
      if (existing != null) return existing;
    }

    final trial = SubscriptionEntitlement.newTrial(DateTime.now());
    await ref.set(
      {
        'subscription': _trialWriteMap(trial),
      },
      SetOptions(merge: true),
    );
    return trial;
  }

  /// Reinicia 7 dias de trial — uso em desenvolvimento / QA.
  Future<SubscriptionEntitlement> resetTrial(String uid) async {
    final trial = SubscriptionEntitlement.newTrial(DateTime.now());
    await _userRef(uid).set(
      {
        'subscription': _trialWriteMap(trial),
      },
      SetOptions(merge: true),
    );
    return trial;
  }

  static Map<String, dynamic> _trialWriteMap(SubscriptionEntitlement trial) {
    return {
      'status': trial.status.name,
      'trialStartedAt': Timestamp.fromDate(trial.trialStartedAt),
      'trialEndsAt': Timestamp.fromDate(trial.trialEndsAt),
      'plan': trial.plan,
      'startedAt': null,
      'expiresAt': null,
      'store': null,
      'productId': null,
      'purchaseTokenFingerprint': null,
      'pixPaymentId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static SubscriptionEntitlement? fromFirestoreMap(Map<String, dynamic> map) {
    DateTime? ts(Object? v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final statusName = map['status'] as String?;
    final trialStart = ts(map['trialStartedAt']);
    final trialEnd = ts(map['trialEndsAt']);
    if (statusName == null || trialStart == null || trialEnd == null) {
      return null;
    }
    final status = SubscriptionStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => SubscriptionStatus.expired,
    );
    return SubscriptionEntitlement(
      status: status,
      trialStartedAt: trialStart,
      trialEndsAt: trialEnd,
      startedAt: ts(map['startedAt']),
      expiresAt: ts(map['expiresAt']),
      plan: (map['plan'] as String?) ?? 'annual_12m',
      store: map['store'] as String?,
      pixPaymentId: map['pixPaymentId'] as String?,
    );
  }
}
