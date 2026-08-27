import 'package:animations/animations.dart';
import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppPageTransitions.theme', () {
    test('wires SharedAxisPageTransitionsBuilder for android and iOS', () {
      final builders = AppPageTransitions.theme.builders;

      expect(
        builders[TargetPlatform.android],
        isA<SharedAxisPageTransitionsBuilder>(),
      );
      expect(
        builders[TargetPlatform.iOS],
        isA<SharedAxisPageTransitionsBuilder>(),
      );
    });
  });
}
