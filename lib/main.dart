import 'package:flutter/material.dart';
import 'package:guardian_portal/app/guardian_portal_app.dart';
import 'package:guardian_portal/core/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapFirebase();
  runApp(const GuardianPortalApp());
}
