import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/app/constants.dart';

void main() {
  test('versão do portal bate com o pubspec e é independente do app', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)', multiLine: true)
        .firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml precisa de version: x.y.z+n');
    expect(AppConstants.portalVersion, match!.group(1));
    expect(AppConstants.portalBuild, int.parse(match.group(2)!));
  });
}
