import 'package:authorization/authorization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_authorization_reader.dart';

void main() {
  const requirement = PermissionRequirement.single('provider:branch:view');

  Widget host(FakeAuthorizationReader reader) => MaterialApp(
    home: PermissionBuilder(
      requirement: requirement,
      reader: reader,
      builder: (context, allowed) => Text(allowed ? 'allowed' : 'denied'),
    ),
  );

  testWidgets(
    'renders allowed=false while unresolved, even with a matching permission',
    (
      tester,
    ) async {
      final reader = FakeAuthorizationReader(
        permissions: PermissionSet.from(const ['provider:branch:view']),
      );
      await tester.pumpWidget(host(reader));

      expect(find.text('denied'), findsOneWidget);
    },
  );

  testWidgets('renders allowed=true once resolved with a matching permission', (
    tester,
  ) async {
    final reader = FakeAuthorizationReader(
      permissions: PermissionSet.from(const ['provider:branch:view']),
      isResolved: true,
    );
    await tester.pumpWidget(host(reader));

    expect(find.text('allowed'), findsOneWidget);
  });

  testWidgets('renders allowed=false when resolved without the permission', (
    tester,
  ) async {
    final reader = FakeAuthorizationReader(isResolved: true);
    await tester.pumpWidget(host(reader));

    expect(find.text('denied'), findsOneWidget);
  });

  testWidgets('rebuilds when the reader emits a decision-relevant change', (
    tester,
  ) async {
    final reader = FakeAuthorizationReader();
    await tester.pumpWidget(host(reader));
    expect(find.text('denied'), findsOneWidget);

    reader.emit(
      permissions: PermissionSet.from(const ['provider:branch:view']),
      isResolved: true,
    );
    await tester.pump();

    expect(find.text('allowed'), findsOneWidget);
  });

  testWidgets(
    'does not rebuild when the reader notifies with no decision change',
    (
      tester,
    ) async {
      final reader = FakeAuthorizationReader(
        permissions: PermissionSet.from(const ['provider:branch:view']),
        isResolved: true,
      );
      var buildCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionBuilder(
            requirement: requirement,
            reader: reader,
            builder: (context, allowed) {
              buildCount++;
              return Text(allowed ? 'allowed' : 'denied');
            },
          ),
        ),
      );
      expect(buildCount, 1);

      // Emit an unrelated notification — same permission set, same resolution.
      reader.emit(
        permissions: PermissionSet.from(const ['provider:branch:view']),
        isResolved: true,
      );
      await tester.pump();

      expect(buildCount, 1, reason: 'no decision-relevant change occurred');
    },
  );

  testWidgets('disposes its listener without error', (tester) async {
    final reader = FakeAuthorizationReader(isResolved: true);
    await tester.pumpWidget(host(reader));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    // Emitting after the widget is gone must not throw.
    reader.emit(
      permissions: PermissionSet.from(const ['provider:branch:view']),
    );
  });
}
