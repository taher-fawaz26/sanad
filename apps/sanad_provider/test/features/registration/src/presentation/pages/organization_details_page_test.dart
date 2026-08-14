import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/cubit/registration_details_cubit.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/pages/organization_details_page.dart';

/// Business-name and representative-name field validation on the
/// organization registration step.
///
/// `organization_details_page.dart`'s validators were confirmed correct
/// against the live backend Swagger:
/// - `businessName` matches `CreateProviderProfileDto.businessName`
///   (minLength 3 / maxLength 255).
/// - `representativeName` is required-only, and intentionally has no length
///   check — there is no matching field on any backend DTO to constrain it.
///
/// These tests lock that behavior in, they do not change it.
///
/// EasyLocalization is intentionally not initialized: `.tr()` falls back to
/// returning the raw key, so assertions target i18n keys, not copy.
void main() {
  late RegistrationDetailsCubit cubit;

  setUp(() {
    cubit = RegistrationDetailsCubit();
  });

  tearDown(() => cubit.close());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: BlocProvider<RegistrationDetailsCubit>.value(
              value: cubit,
              child: const SingleChildScrollView(
                child: OrganizationDetailsPage(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Business name is the first AppTextField/TextField, representative name
  // is the second.
  Future<void> enterBusinessName(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextField).first, value);
    await tester.pump();
  }

  Future<void> enterRepresentativeName(
    WidgetTester tester,
    String value,
  ) async {
    await tester.enterText(find.byType(TextField).last, value);
    await tester.pump();
  }

  group('business name', () {
    testWidgets('empty shows the required error key', (tester) async {
      await pumpPage(tester);

      await enterBusinessName(tester, 'a');
      await enterBusinessName(tester, '');

      expect(find.text('registration.field_required'), findsOneWidget);
    });

    testWidgets('too short shows the length error key', (tester) async {
      await pumpPage(tester);

      await enterBusinessName(tester, 'ab');

      expect(find.text('validation.length_range'), findsOneWidget);
    });

    testWidgets('too long shows the length error key', (tester) async {
      await pumpPage(tester);

      await enterBusinessName(tester, 'a' * 256);

      expect(find.text('validation.length_range'), findsOneWidget);
    });

    testWidgets('valid 3-255 chars passes with no error', (tester) async {
      await pumpPage(tester);

      await enterBusinessName(tester, 'Acme LLC');

      expect(find.text('registration.field_required'), findsNothing);
      expect(find.text('validation.length_range'), findsNothing);
    });
  });

  group('representative name', () {
    testWidgets('empty shows the required error key', (tester) async {
      await pumpPage(tester);

      await enterRepresentativeName(tester, 'a');
      await enterRepresentativeName(tester, '');

      expect(find.text('registration.field_required'), findsOneWidget);
    });

    testWidgets('1 char passes — no length constraint applies', (
      tester,
    ) async {
      await pumpPage(tester);

      await enterRepresentativeName(tester, 'A');

      expect(find.text('registration.field_required'), findsNothing);
      expect(find.text('validation.length_range'), findsNothing);
    });

    testWidgets('500 chars passes — no length constraint applies', (
      tester,
    ) async {
      await pumpPage(tester);

      await enterRepresentativeName(tester, 'a' * 500);

      expect(find.text('registration.field_required'), findsNothing);
      expect(find.text('validation.length_range'), findsNothing);
    });
  });
}
