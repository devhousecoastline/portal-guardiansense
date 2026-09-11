import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guardian_portal/features/account/data/user_repository.dart';
import 'package:guardian_portal/features/account/domain/user_plan.dart';
import 'package:guardian_portal/features/auth/application/auth_controller.dart';

/// Plano comercial único na sessão — evita N streams e flash do badge Premium.
class UserPlanController extends ChangeNotifier {
  UserPlanController({UserRepository? repository})
      : _repository = repository ?? UserRepository();

  final UserRepository _repository;
  AuthController? _auth;
  StreamSubscription<UserPlan>? _sub;
  String? _uid;

  UserPlan _plan = const UserPlan(
    plan: 'pending',
    deviceLimit: 1,
    isEntitled: true,
  );

  UserPlan get plan => _plan;

  void attachAuth(AuthController auth) {
    if (identical(_auth, auth)) return;
    _auth?.removeListener(_onAuthChanged);
    _auth = auth;
    auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    final uid = _auth?.user?.uid;
    if (uid == _uid) return;
    _uid = uid;
    _sub?.cancel();
    _sub = null;

    if (uid == null) {
      _plan = UserPlan.free;
      notifyListeners();
      return;
    }

    // Mantém entitled até o 1º snapshot (sem flash de cadeado).
    _plan = UserRepository.planForUi(uid, null);
    notifyListeners();

    _sub = _repository.watchPlan(uid).listen(
      (plan) {
        _plan = plan;
        UserRepository.planForUi(uid, plan);
        notifyListeners();
      },
      onError: (_) {
        // Mantém o último plano conhecido.
      },
    );
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    _sub?.cancel();
    super.dispose();
  }
}

class UserPlanScope extends InheritedNotifier<UserPlanController> {
  const UserPlanScope({
    super.key,
    required UserPlanController controller,
    required super.child,
  }) : super(notifier: controller);

  static UserPlan of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UserPlanScope>();
    assert(scope != null, 'UserPlanScope não encontrado');
    return scope!.notifier!.plan;
  }

  static UserPlan? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<UserPlanScope>()
        ?.notifier
        ?.plan;
  }
}
