import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  AuthController({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _subscription = _auth.authStateChanges().listen((_) {
      _ready = true;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;
  bool _ready = false;

  /// Primeira emissão de [authStateChanges] — evita flash de login no refresh.
  bool get isReady => _ready;

  User? get user => _auth.currentUser;
  bool get isSignedIn => user != null;

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> registerWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Login com Google — mesmo provedor do app mobile (Firebase popup no Web).
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      await _auth.signInWithPopup(provider).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw FirebaseAuthException(
          code: 'popup-closed-by-user',
          message: 'Login com Google cancelado.',
        ),
      );
      return;
    }
    await _auth.signInWithProvider(provider);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
