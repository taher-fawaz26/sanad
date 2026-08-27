import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

Finder _semanticsOf(Finder of) =>
    find.descendant(of: of, matching: find.byType(Semantics)).first;

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('AppIconButton', () {
    testWidgets('calls onTap and exposes the semantic label', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        AppIconButton(
          icon: Icons.delete_outline,
          onTap: () => tapped = true,
          semanticLabel: 'Delete',
        ),
      );

      final semantics = tester.widget<Semantics>(
        _semanticsOf(find.byType(AppIconButton)),
      );
      expect(semantics.properties.label, 'Delete');
      expect(semantics.properties.button, isTrue);

      await tester.tap(find.byType(AppIconButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('onTap null is reported as disabled in semantics', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppIconButton(
          icon: Icons.delete_outline,
          onTap: null,
          semanticLabel: 'Delete',
        ),
      );

      final semantics = tester.widget<Semantics>(
        _semanticsOf(find.byType(AppIconButton)),
      );
      expect(semantics.properties.enabled, isFalse);
    });

    testWidgets('small size meets the 44dp minimum touch target', (
      tester,
    ) async {
      await _pump(
        tester,
        AppIconButton(
          icon: Icons.add,
          onTap: () {},
          semanticLabel: 'Add',
        ),
      );

      final size = tester.getSize(find.byType(AppIconButton));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('large size meets the 48dp minimum touch target', (
      tester,
    ) async {
      await _pump(
        tester,
        AppIconButton(
          icon: Icons.add,
          size: AppIconButtonSize.large,
          onTap: () {},
          semanticLabel: 'Add',
        ),
      );

      final size = tester.getSize(find.byType(AppIconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('destructive intent tints the icon with the error color', (
      tester,
    ) async {
      await _pump(
        tester,
        AppIconButton(
          icon: Icons.delete_outline,
          intent: AppButtonIntent.destructive,
          onTap: () {},
          semanticLabel: 'Delete',
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      final context = tester.element(find.byType(AppIconButton));
      expect(icon.color, context.appColors.error);
    });

    testWidgets('explicit iconColor overrides the intent default', (
      tester,
    ) async {
      await _pump(
        tester,
        AppIconButton(
          icon: Icons.add,
          iconColor: Colors.purple,
          onTap: () {},
          semanticLabel: 'Add',
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.purple);
    });
  });
}
