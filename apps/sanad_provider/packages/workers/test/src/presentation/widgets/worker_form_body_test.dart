import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workers/src/presentation/widgets/worker_form_body.dart';

// ── Root-cause note ──────────────────────────────────────────────────────
// This file intentionally does NOT bootstrap EasyLocalization — see
// worker_list_item_test.dart for the full explanation. `.tr()` falls back
// to the raw key, so assertions below match on raw i18n keys (e.g.
// 'validation.required'), not translated text.

Future<void> _pump(
  WidgetTester tester, {
  required GlobalKey<FormState> formKey,
  bool showValidationErrors = true,
  bool requireContact = true,
  bool emailReadOnly = false,
  ValueChanged<bool>? onCompletenessChanged,
  Key? bodyKey,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: WorkerFormBody(
              key: bodyKey,
              formKey: formKey,
              showValidationErrors: showValidationErrors,
              requireContact: requireContact,
              emailReadOnly: emailReadOnly,
              onCompletenessChanged: onCompletenessChanged,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late GlobalKey<FormState> formKey;

  setUp(() {
    formKey = GlobalKey<FormState>();
  });

  Future<void> validate(WidgetTester tester) async {
    formKey.currentState!.validate();
    await tester.pumpAndSettle();
  }

  group('full name', () {
    testWidgets('empty shows required error', (tester) async {
      await _pump(tester, formKey: formKey);
      await validate(tester);

      expect(
        find.text('validation.required'),
        findsWidgets,
      );
    });

    testWidgets('too short (<3 chars) shows length error', (tester) async {
      await _pump(tester, formKey: formKey);

      await tester.enterText(find.byType(TextField).at(0), 'Al');
      await validate(tester);

      expect(
        find.text('validation.length_range'),
        findsOneWidget,
      );
    });

    testWidgets('too long (>255 chars) shows length error', (tester) async {
      await _pump(tester, formKey: formKey);

      await tester.enterText(find.byType(TextField).at(0), 'A' * 256);
      await validate(tester);

      expect(
        find.text('validation.length_range'),
        findsOneWidget,
      );
    });

    testWidgets('digits show format error', (tester) async {
      await _pump(tester, formKey: formKey);

      await tester.enterText(find.byType(TextField).at(0), 'Ahmed123');
      await validate(tester);

      expect(
        find.text('workers.add_worker.validation_name_format'),
        findsOneWidget,
      );
    });

    testWidgets('valid single-word name passes', (tester) async {
      await _pump(tester, formKey: formKey);

      await tester.enterText(find.byType(TextField).at(0), 'Ahmed');
      await validate(tester);

      expect(
        find.text('workers.add_worker.validation_name_format'),
        findsNothing,
      );
      expect(
        find.text('validation.length_range'),
        findsNothing,
      );
    });

    testWidgets('valid two-word name passes', (tester) async {
      await _pump(tester, formKey: formKey);

      await tester.enterText(find.byType(TextField).at(0), 'Ahmed Ali');
      await validate(tester);

      expect(
        find.text('workers.add_worker.validation_name_format'),
        findsNothing,
      );
      expect(
        find.text('validation.length_range'),
        findsNothing,
      );
    });
  });

  group('email (requireContact: true)', () {
    testWidgets('empty shows required error', (tester) async {
      await _pump(tester, formKey: formKey);
      await validate(tester);

      expect(
        find.text('validation.required'),
        findsWidgets,
      );
    });

    testWidgets('invalid format shows email error', (tester) async {
      await _pump(tester, formKey: formKey);

      await tester.enterText(find.byType(TextField).at(1), 'not-an-email');
      await validate(tester);

      expect(find.text('workers.add_worker.validation_email'), findsOneWidget);
    });

    testWidgets('reserved domain shows reserved-domain error', (
      tester,
    ) async {
      await _pump(tester, formKey: formKey);

      await tester.enterText(
        find.byType(TextField).at(1),
        'someone@example.com',
      );
      await validate(tester);

      expect(
        find.text('workers.add_worker.validation_reserved_domain'),
        findsOneWidget,
      );
    });

    testWidgets('valid email passes', (tester) async {
      await _pump(tester, formKey: formKey);

      await tester.enterText(
        find.byType(TextField).at(1),
        'someone@sanad.com',
      );
      await validate(tester);

      expect(find.text('workers.add_worker.validation_email'), findsNothing);
      expect(
        find.text('workers.add_worker.validation_reserved_domain'),
        findsNothing,
      );
    });
  });

  group('phone (requireContact: true)', () {
    testWidgets('empty shows required error', (tester) async {
      await _pump(tester, formKey: formKey);
      await validate(tester);

      expect(
        find.text('validation.required'),
        findsWidgets,
      );
    });

    testWidgets('malformed non-empty shows distinct format error, not '
        'required', (tester) async {
      await _pump(tester, formKey: formKey);

      await tester.enterText(find.byType(TextField).at(2), '123');
      await validate(tester);

      expect(
        find.text('validation.form.uae_phone_invalid'),
        findsOneWidget,
      );
    });

    testWidgets('valid UAE number passes', (tester) async {
      final bodyKey = GlobalKey<WorkerFormBodyState>();
      await _pump(tester, formKey: formKey, bodyKey: bodyKey);

      await tester.enterText(find.byType(TextField).at(2), '501234567');
      await validate(tester);

      expect(find.text('validation.form.uae_phone_invalid'), findsNothing);
      expect(bodyKey.currentState!.isPhoneValid, isTrue);
      expect(bodyKey.currentState!.phone, '+971501234567');
    });
  });

  group('job title', () {
    testWidgets('empty shows no error', (tester) async {
      await _pump(tester, formKey: formKey);
      await validate(tester);

      expect(
        find.text('validation.length_max'),
        findsNothing,
      );
    });

    testWidgets('too long (>255 chars) shows length error', (tester) async {
      await _pump(tester, formKey: formKey);

      await tester.enterText(find.byType(TextField).at(3), 'A' * 256);
      await validate(tester);

      expect(
        find.text('validation.length_max'),
        findsOneWidget,
      );
    });

    testWidgets('valid value passes', (tester) async {
      await _pump(tester, formKey: formKey);

      await tester.enterText(find.byType(TextField).at(3), 'Technician');
      await validate(tester);

      expect(
        find.text('validation.length_max'),
        findsNothing,
      );
    });
  });

  group('worker type', () {
    testWidgets('unselected + submit attempt shows required error', (
      tester,
    ) async {
      await _pump(tester, formKey: formKey);
      await validate(tester);

      expect(
        find.text('validation.required'),
        findsWidgets,
      );
    });
  });
}
