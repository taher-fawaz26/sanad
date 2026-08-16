import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  // AppEnhanceWithAiButton runs a perpetual rainbow-border animation unless
  // disabled — stopping it here keeps pumpAndSettle() from hanging.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  group('AppDescriptionField', () {
    testWidgets('renders label and hint', (tester) async {
      await _pump(
        tester,
        const AppDescriptionField(label: 'Description', hint: 'Tell us more'),
      );

      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Tell us more'), findsOneWidget);
    });

    testWidgets('shows the required indicator only when isRequired is true', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppDescriptionField(label: 'Description', isRequired: true),
      );

      final label = tester.widget<AppFieldLabel>(find.byType(AppFieldLabel));
      expect(label.isRequired, isTrue);
    });

    testWidgets('is multiline by default', (tester) async {
      await _pump(tester, const AppDescriptionField(label: 'Description'));

      final field = tester.widget<AppTextField>(find.byType(AppTextField));
      expect(field.maxLines, greaterThan(1));
    });

    testWidgets('shows a live character count when maxLength is set', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'hello');
      addTearDown(controller.dispose);

      await _pump(
        tester,
        AppDescriptionField(
          label: 'Description',
          controller: controller,
          maxLength: 500,
        ),
      );

      expect(find.text('5/500'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'hello world');
      await tester.pump();

      expect(find.text('11/500'), findsOneWidget);
    });

    testWidgets(
      'hides the character count when showCharacterCount is false',
      (tester) async {
        final controller = TextEditingController(text: 'hello');
        addTearDown(controller.dispose);

        await _pump(
          tester,
          AppDescriptionField(
            label: 'Description',
            controller: controller,
            maxLength: 500,
            showCharacterCount: false,
          ),
        );

        expect(find.text('5/500'), findsNothing);
      },
    );

    testWidgets('renders the external errorText', (tester) async {
      await _pump(
        tester,
        const AppDescriptionField(
          label: 'Description',
          errorText: 'Something went wrong',
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('disables the field when enabled is false', (tester) async {
      await _pump(
        tester,
        const AppDescriptionField(label: 'Description', enabled: false),
      );

      final field = tester.widget<AppTextField>(find.byType(AppTextField));
      expect(field.enabled, isFalse);
    });

    testWidgets('is read-only when readOnly is true', (tester) async {
      await _pump(
        tester,
        const AppDescriptionField(label: 'Description', readOnly: true),
      );

      final field = tester.widget<AppTextField>(find.byType(AppTextField));
      expect(field.readOnly, isTrue);
    });

    testWidgets('hides the AI action when aiActionLabel is null', (
      tester,
    ) async {
      await _pump(tester, const AppDescriptionField(label: 'Description'));

      expect(find.byType(AppEnhanceWithAiButton), findsNothing);
    });

    testWidgets('shows the AI action when aiActionLabel is set', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppDescriptionField(
          label: 'Description',
          aiActionLabel: 'Enhance',
        ),
      );

      expect(find.byType(AppEnhanceWithAiButton), findsOneWidget);
      expect(find.text('Enhance'), findsOneWidget);
    });

    testWidgets('fires onImproveWithAi when the AI action is tapped', (
      tester,
    ) async {
      var tapped = false;
      await _pump(
        tester,
        AppDescriptionField(
          label: 'Description',
          aiActionLabel: 'Enhance',
          onImproveWithAi: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(AppEnhanceWithAiButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets(
      'disables the AI action when onImproveWithAi is null',
      (tester) async {
        await _pump(
          tester,
          const AppDescriptionField(
            label: 'Description',
            aiActionLabel: 'Enhance',
          ),
        );

        final button = tester.widget<AppEnhanceWithAiButton>(
          find.byType(AppEnhanceWithAiButton),
        );
        expect(button.onTap, isNull);
      },
    );

    testWidgets(
      'disables the AI action and reflects isImprovingWithAi as loading',
      (tester) async {
        await _pump(
          tester,
          AppDescriptionField(
            label: 'Description',
            aiActionLabel: 'Enhance',
            onImproveWithAi: () {},
            isImprovingWithAi: true,
          ),
        );

        final button = tester.widget<AppEnhanceWithAiButton>(
          find.byType(AppEnhanceWithAiButton),
        );
        expect(button.isLoading, isTrue);
      },
    );
  });
}
