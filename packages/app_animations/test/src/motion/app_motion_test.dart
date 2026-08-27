import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppMotion.reduceMotionOf', () {
    testWidgets('false by default', (tester) async {
      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppMotion.reduceMotionOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, isFalse);
    });

    testWidgets('true when disableAnimations is set', (tester) async {
      late bool result;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                result = AppMotion.reduceMotionOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(result, isTrue);
    });

    testWidgets('true when accessibleNavigation is set', (tester) async {
      late bool result;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(accessibleNavigation: true),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                result = AppMotion.reduceMotionOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(result, isTrue);
    });
  });
}
