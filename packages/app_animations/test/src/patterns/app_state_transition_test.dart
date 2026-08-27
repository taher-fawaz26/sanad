import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Status { loading, success, error }

void main() {
  group('AppStateTransition', () {
    testWidgets('renders the widget for the initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppStateTransition<_Status>(
            value: _Status.loading,
            builder: (context, value) => Text(value.name),
          ),
        ),
      );

      expect(find.text('loading'), findsOneWidget);
    });

    testWidgets('switches child when value changes', (tester) async {
      final notifier = ValueNotifier(_Status.loading);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<_Status>(
            valueListenable: notifier,
            builder: (context, value, _) => AppStateTransition<_Status>(
              value: value,
              builder: (context, v) => Text(v.name),
            ),
          ),
        ),
      );
      expect(find.text('loading'), findsOneWidget);

      notifier.value = _Status.success;
      await tester.pumpAndSettle();

      expect(find.text('success'), findsOneWidget);
      expect(find.text('loading'), findsNothing);

      notifier.value = _Status.error;
      await tester.pumpAndSettle();

      expect(find.text('error'), findsOneWidget);
      expect(find.text('success'), findsNothing);
    });
  });
}
