import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:text_optimization/text_optimization.dart';

class _MockTextOptimizationRepository extends Mock
    implements TextOptimizationRepository {}

Future<void> _pump(
  WidgetTester tester,
  TextOptimizationCubit cubit, {
  required TextEditingController controller,
  ValueChanged<String>? onChanged,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiEnhanceDescriptionField(
              label: 'Description',
              aiActionLabel: 'Enhance',
              controller: controller,
              onChanged: onChanged,
              cubit: cubit,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _MockTextOptimizationRepository repository;
  late TextOptimizationCubit cubit;
  late TextEditingController controller;

  setUp(() {
    repository = _MockTextOptimizationRepository();
    cubit = TextOptimizationCubit(OptimizeTextUseCase(repository));
    controller = TextEditingController(text: 'a rough draft');
  });

  tearDown(() {
    cubit.close();
    controller.dispose();
  });

  testWidgets(
    'tapping Enhance replaces the controller text with the optimized '
    'result and calls onChanged',
    (tester) async {
      when(
        () => repository.optimize('a rough draft'),
      ).thenAnswer((_) => TaskEither.right('A polished draft.'));
      final changed = <String>[];

      await _pump(
        tester,
        cubit,
        controller: controller,
        onChanged: changed.add,
      );

      await tester.tap(find.byType(AppEnhanceWithAiButton));
      await tester.pump();
      await tester.pump();

      expect(controller.text, 'A polished draft.');
      expect(controller.selection.baseOffset, controller.text.length);
      expect(changed, ['A polished draft.']);
    },
  );

  testWidgets(
    'a failure shows a snackbar and never touches the controller text',
    (tester) async {
      when(() => repository.optimize('a rough draft')).thenAnswer(
        (_) => TaskEither.left(
          const ServerFailure(message: "I can't rewrite gibberish."),
        ),
      );

      await _pump(tester, cubit, controller: controller);

      await tester.tap(find.byType(AppEnhanceWithAiButton));
      await tester.pump();
      await tester.pump();

      expect(controller.text, 'a rough draft');
      expect(find.text("I can't rewrite gibberish."), findsOneWidget);
    },
  );

  testWidgets('the button reflects the cubit loading state', (tester) async {
    when(() => repository.optimize('a rough draft')).thenAnswer(
      (_) => TaskEither(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const Right('done');
      }),
    );

    await _pump(tester, cubit, controller: controller);

    await tester.tap(find.byType(AppEnhanceWithAiButton));
    await tester.pump();

    var button = tester.widget<AppEnhanceWithAiButton>(
      find.byType(AppEnhanceWithAiButton),
    );
    expect(button.isLoading, isTrue);

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    button = tester.widget<AppEnhanceWithAiButton>(
      find.byType(AppEnhanceWithAiButton),
    );
    expect(button.isLoading, isFalse);
  });
}
