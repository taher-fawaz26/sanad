import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/cubit/registration_details_cubit.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/pages/individual_details_page.dart';

/// Full-name field validation on the individual registration step.
///
/// `individual_details_page.dart`'s validator was confirmed correct against
/// the live backend Swagger (`CreateProviderProfileDto.fullName`,
/// minLength 3 / maxLength 255) — these tests lock that behavior in, they do
/// not change it.
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
                child: IndividualDetailsPage(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> enterFullName(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextField), value);
    await tester.pump();
  }

  testWidgets('empty full name shows the required error key', (
    tester,
  ) async {
    await pumpPage(tester);

    // Enter then clear so the field registers user interaction — the
    // validator runs under AutovalidateMode.onUserInteraction.
    await enterFullName(tester, 'a');
    await enterFullName(tester, '');

    expect(find.text('registration.field_required'), findsOneWidget);
  });

  testWidgets('2-char full name shows the length error key', (tester) async {
    await pumpPage(tester);

    await enterFullName(tester, 'ab');

    expect(find.text('registration.name_length_error'), findsOneWidget);
  });

  testWidgets('256-char full name shows the length error key', (
    tester,
  ) async {
    await pumpPage(tester);

    await enterFullName(tester, 'a' * 256);

    expect(find.text('registration.name_length_error'), findsOneWidget);
  });

  testWidgets('valid 3-255 char full name passes with no error', (
    tester,
  ) async {
    await pumpPage(tester);

    await enterFullName(tester, 'John Doe');

    expect(find.text('registration.field_required'), findsNothing);
    expect(find.text('registration.name_length_error'), findsNothing);
  });
}
