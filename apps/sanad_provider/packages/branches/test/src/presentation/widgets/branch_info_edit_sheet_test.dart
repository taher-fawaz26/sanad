import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/presentation/widgets/branch_info_edit_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// No EasyLocalization bootstrap (matches branch_review_body_test.dart's
// convention) — `.tr()` falls back to the raw i18n key, so assertions target
// those raw keys directly.

// Wide surface: with no EasyLocalization bootstrap, `.tr()` falls back to
// raw (long) i18n keys, which can overflow rows at normal phone widths.
const _surfaceSize = Size(2400, 1600);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    String initialName = 'Downtown Branch',
    BranchType initialType = BranchType.mainBranch,
  }) async {
    await tester.binding.setSurfaceSize(_surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: _surfaceSize,
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: BranchInfoEditSheet(
              initialName: initialName,
              initialType: initialType,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder nameField() => find.descendant(
    of: find.byType(AppTextField),
    matching: find.byType(TextField),
  );

  AppButton saveButton(WidgetTester tester) =>
      tester.widget<AppButton>(find.byType(AppButton));

  group('BranchInfoEditSheet — branch name validation', () {
    testWidgets(
      'starts valid with a pre-filled name from the seeded branch (Save '
      'disabled only because nothing changed yet)',
      (tester) async {
        await pump(tester);

        expect(
          find.text('branches.add_branch.branch_name_required'),
          findsNothing,
        );
        expect(
          find.text('branches.add_branch.branch_name_max_length_error'),
          findsNothing,
        );
        expect(saveButton(tester).onPressed, isNull);
      },
    );

    testWidgets('clearing the name shows the required error', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(nameField(), '');
      await tester.pump();

      expect(
        find.text('branches.add_branch.branch_name_required'),
        findsOneWidget,
      );
      expect(saveButton(tester).onPressed, isNull);
    });

    testWidgets(
      '256 characters shows the max-length error (no minimum enforced)',
      (tester) async {
        await pump(tester);

        await tester.enterText(nameField(), 'a' * 256);
        await tester.pump();

        expect(
          find.text('branches.add_branch.branch_name_max_length_error'),
          findsOneWidget,
        );
        expect(saveButton(tester).onPressed, isNull);
      },
    );

    testWidgets('exactly 255 characters passes and enables Save', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(nameField(), 'a' * 255);
      await tester.pump();

      expect(
        find.text('branches.add_branch.branch_name_max_length_error'),
        findsNothing,
      );
      expect(saveButton(tester).onPressed, isNotNull);
    });

    testWidgets(
      'a short (2-char) name is valid and enables Save — no invented '
      'minimum',
      (tester) async {
        await pump(tester);

        await tester.enterText(nameField(), 'AB');
        await tester.pump();

        expect(
          find.text('branches.add_branch.branch_name_required'),
          findsNothing,
        );
        expect(
          find.text('branches.add_branch.branch_name_max_length_error'),
          findsNothing,
        );
        expect(saveButton(tester).onPressed, isNotNull);
      },
    );
  });
}
