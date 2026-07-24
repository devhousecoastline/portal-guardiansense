import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuração Firebase — mesmo projeto do app mobile (`guardian-sense-dbdfa`).
///
/// Para regenerar com app Web registrado no console:
/// `dart pub global activate flutterfire_cli && flutterfire configure`
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Guardian Portal é apenas Web. Plataforma: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCtaVMMa8GUKwwRUhl4Ai0jKLzptFEsa7I',
    appId: '1:74607962213:web:59a3360f830a65e6467e8c',
    messagingSenderId: '74607962213',
    projectId: 'guardian-sense-dbdfa',
    authDomain: 'guardian-sense-dbdfa.firebaseapp.com',
    storageBucket: 'guardian-sense-dbdfa.firebasestorage.app',
    measurementId: 'G-31BSWEGQMH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC58bPZIg-RPJX41EHmTbftRd4A3FDjOII',
    appId: '1:74607962213:android:2160965843dc302d467e8c',
    messagingSenderId: '74607962213',
    projectId: 'guardian-sense-dbdfa',
    storageBucket: 'guardian-sense-dbdfa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC58bPZIg-RPJX41EHmTbftRd4A3FDjOII',
    appId: '1:74607962213:ios:0000000000000000000000',
    messagingSenderId: '74607962213',
    projectId: 'guardian-sense-dbdfa',
    storageBucket: 'guardian-sense-dbdfa.firebasestorage.app',
    iosBundleId: 'com.guardiansense.app',
  );
}
