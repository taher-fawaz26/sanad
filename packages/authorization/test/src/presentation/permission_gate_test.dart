import 'package:authorization/authorization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_authorization_reader.dart';

void main() {
  const childKey = Key('gated-child');

  testWidgets('hides (default) when the permission is denied', (tester) async {
    final reader = FakeAuthorizationReader(isResolved: true);
    await tester.pumpWidget(
      MaterialApp(
        home: PermissionGate(
          permission: 'provider:branch:create',
          reader: reader,
          child: const SizedBox(key: childKey),
        ),
      ),
    );

    expect(find.byKey(childKey), findsNothing);
  });

  testWidgets('shows the child when the permission is granted', (tester) async {
    final reader = FakeAuthorizationReader(
      permissions: PermissionSet.from(const ['provider:branch:create']),
      isResolved: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PermissionGate(
          permission: 'provider:branch:create',
          reader: reader,
          child: const SizedBox(key: childKey),
        ),
      ),
    );

    expect(find.byKey(childKey), findsOneWidget);
  });

  testWidgets('renders the fallback when denied and a fallback is supplied', (
    tester,
  ) async {
    final reader = FakeAuthorizationReader(isResolved: true);
    await tester.pumpWidget(
      MaterialApp(
        home: PermissionGate(
          permission: 'provider:branch:create',
          reader: reader,
          fallback: const Text('no access'),
          child: const SizedBox(key: childKey),
        ),
      ),
    );

    expect(find.byKey(childKey), findsNothing);
    expect(find.text('no access'), findsOneWidget);
  });

  testWidgets(
    'disabled: true keeps the child in the tree but ignores pointer events',
    (
      tester,
    ) async {
      var tapped = false;
      final reader = FakeAuthorizationReader(isResolved: true);
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionGate(
            permission: 'provider:branch:update',
            reader: reader,
            disabled: true,
            child: ElevatedButton(
              key: childKey,
              onPressed: () => tapped = true,
              child: const Text('Edit'),
            ),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
      // warnIfMissed: false — IgnorePointer deliberately removes the button
      // from hit-testing, so the tap not landing IS the behavior under test.
      await tester.tap(find.byKey(childKey), warnIfMissed: false);
      await tester.pump();
      expect(tapped, isFalse, reason: 'IgnorePointer must swallow the tap');

      final opacity = tester.widget<Opacity>(
        find
            .ancestor(of: find.byKey(childKey), matching: find.byType(Opacity))
            .first,
      );
      expect(opacity.opacity, lessThan(1));
    },
  );

  testWidgets(
    'disabled: true renders at full opacity and is tappable when allowed',
    (
      tester,
    ) async {
      var tapped = false;
      final reader = FakeAuthorizationReader(
        permissions: PermissionSet.from(const ['provider:branch:update']),
        isResolved: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionGate(
            permission: 'provider:branch:update',
            reader: reader,
            disabled: true,
            child: ElevatedButton(
              key: childKey,
              onPressed: () => tapped = true,
              child: const Text('Edit'),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(childKey));
      await tester.pump();
      expect(tapped, isTrue);
    },
  );

  group('PermissionGate.requiring (any/all composition)', () {
    testWidgets('any — visible if at least one of the actions is granted', (
      tester,
    ) async {
      final reader = FakeAuthorizationReader(
        permissions: PermissionSet.from(const ['provider:branch:update']),
        isResolved: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionGate.requiring(
            requirement: const PermissionRequirement.any({
              'provider:branch:create',
              'provider:branch:update',
            }),
            reader: reader,
            child: const SizedBox(key: childKey),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
    });

    testWidgets('all — hidden unless every required action is granted', (
      tester,
    ) async {
      final reader = FakeAuthorizationReader(
        permissions: PermissionSet.from(const ['provider:branch:view']),
        isResolved: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionGate.requiring(
            requirement: const PermissionRequirement.all({
              'provider:branch:view',
              'provider:branch:update',
            }),
            reader: reader,
            child: const SizedBox(key: childKey),
          ),
        ),
      );

      expect(find.byKey(childKey), findsNothing);
    });
  });

  testWidgets(
    'rebuilds from hidden to visible when permissions are granted at runtime',
    (
      tester,
    ) async {
      final reader = FakeAuthorizationReader(isResolved: true);
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionGate(
            permission: 'provider:branch:create',
            reader: reader,
            child: const SizedBox(key: childKey),
          ),
        ),
      );
      expect(find.byKey(childKey), findsNothing);

      reader.emit(
        permissions: PermissionSet.from(const ['provider:branch:create']),
      );
      await tester.pump();

      expect(find.byKey(childKey), findsOneWidget);
    },
  );

  testWidgets(
    'throws ArgumentError when permission is neither String nor requirement',
    (tester) async {
      final reader = FakeAuthorizationReader(isResolved: true);
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionGate(
            permission: 42,
            reader: reader,
            child: const SizedBox(key: childKey),
          ),
        ),
      );

      expect(tester.takeException(), isA<ArgumentError>());
    },
  );
}
