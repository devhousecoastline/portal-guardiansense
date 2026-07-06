import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/account/domain/user_plan.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<UserPlan> watchPlan(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) => UserPlan.fromFirestore(doc.data()),
        );
  }
}
