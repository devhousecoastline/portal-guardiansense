import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/account/domain/user_plan.dart';
import 'package:guardian_portal/features/devices/domain/device_switches.dart';

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
}
