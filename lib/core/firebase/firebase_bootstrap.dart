import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:guardian_portal/core/firebase/firebase_options.dart';

/// Inicializa Firebase de forma best-effort (portal depende da nuvem).
Future<bool> bootstrapFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e) {
    debugPrint('Firebase indisponível: $e');
    return false;
  }
}
