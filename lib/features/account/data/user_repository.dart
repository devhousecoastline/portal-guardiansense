import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/account/domain/user_plan.dart';
import 'package:guardian_portal/features/devices/domain/device_switches.dart';
import 'package:guardian_portal/features/info/domain/portal_privacy_consent.dart';

/// Metadados de vínculo/cota lidos de `users/{uid}` (sem a coleção devices).
class UserDevicesMeta {
  const UserDevicesMeta({
    required this.plan,
    required this.switches,
    this.boundDeviceId,
  });

  final UserPlan plan;
  final DeviceSwitches switches;
  final String? boundDeviceId;
}

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection('users').doc(uid);

  Stream<UserPlan> watchPlan(String uid) {
    return watchDevicesMeta(uid).map((meta) => meta.plan);
  }

  Stream<UserDevicesMeta> watchDevicesMeta(String uid) {
    return _user(uid).snapshots().map((doc) {
      final data = doc.data();
      final bound = (data?['boundDeviceId'] as String?)?.trim();
      return UserDevicesMeta(
        plan: UserPlan.fromFirestore(data),
        switches: DeviceSwitches.fromUserDoc(data),
        boundDeviceId: (bound == null || bound.isEmpty) ? null : bound,
      );
    });
  }

  Stream<PortalPrivacyConsent> watchPortalPrivacyConsent(String uid) {
    return _user(uid).snapshots().map((doc) {
      final data = doc.data();
      final raw = data?[PortalPrivacyConsent.firestoreField];
      if (raw is! Map) return const PortalPrivacyConsent();
      final map = Map<String, dynamic>.from(raw);
      return PortalPrivacyConsent(
        version: (map['version'] as String?)?.trim(),
        acceptedAt: _asDate(map['acceptedAt']),
      );
    });
  }

  Future<void> acceptPortalPrivacyPolicy({
    required String uid,
    required String version,
  }) {
    return _user(uid).set(
      {
        PortalPrivacyConsent.firestoreField: {
          'version': version,
          'acceptedAt': FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true),
    );
  }

  static DateTime? _asDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
