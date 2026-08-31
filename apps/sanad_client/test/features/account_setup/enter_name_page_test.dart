// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys (see oauth_test_harness.dart /
// auth_page_test.dart for the same convention).

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_cubit.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_routes.dart';
import 'package:sanad_client/src/features/account_setup/enter_name_page.dart';
import 'package:sanad_client/src/features/account_setup/get_notified_page.dart';

import '../../support/client_auth_test_locator.dart';
import '../oauth/oauth_test_harness.dart';

Finder _nextButtonFinder() => find.widgetWithText(AppButton, 'common.next');

AccountSetupCubit _newCubit() => AccountSetupCubit(
  updateProfile: sl<UpdateClientProfileUseCase>(),
  sessionManager: sl<SessionManager>(),
);

Widget _withCubit(Widget child) =>
    BlocProvider(create: (_) => _newCubit(), child: child);

Future<void> _pumpEnterName(WidgetTester tester) =>
    pumpOAuth(tester, _withCubit(const EnterNamePage()));

void main() {
  setUpAll(registerClientAuthFallbacks);
  setUp(registerClientAuthMocks);
  tearDown(unregisterClientAuthMocks);

  testWidgets('renders back button, icon, title, subtitle and name field', (
    tester,
  ) async {
    await _pumpEnterName(tester);

    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.text('enter_name.title'), findsOneWidget);
    expect(find.text('enter_name.subtitle'), findsOneWidget);
    expect(find.text('enter_name.field_label'), findsOneWidget);
    expect(_nextButtonFinder(), findsOneWidget);
  });

  testWidgets('Next is disabled while the name field is empty', (
    tester,
  ) async {
    await _pumpEnterName(tester);

    final button = tester.widget<AppButton>(_nextButtonFinder());
    expect(button.onPressed, isNull);
  });

  testWidgets('Next is enabled for a single-word name', (tester) async {
    await _pumpEnterName(tester);

    await tester.enterText(find.byType(TextField), 'Mohamed');
    await tester.pump();

    final button = tester.widget<AppButton>(_nextButtonFinder());
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Next stays disabled for a name with invalid characters', (
    tester,
  ) async {
    await _pumpEnterName(tester);

    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();

    final button = tester.widget<AppButton>(_nextButtonFinder());
    expect(button.onPressed, isNull);
  });

  testWidgets('shows an inline error for an invalid name', (tester) async {
    await _pumpEnterName(tester);

    await tester.enterText(find.byType(TextField), '12345');
    // autovalidateMode: onUserInteraction — a second edit re-triggers
    // validation after the field has been touched once.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    expect(find.text('validation.invalid_name'), findsOneWidget);
  });

  testWidgets(
    'name field is not forced LTR — it follows the ambient locale, unlike '
    'email/phone',
    (tester) async {
      await _pumpEnterName(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, isNull);
    },
  );

  group('navigation to the shared Get Notified screen', () {
    GoRouter buildRouter() => GoRouter(
      initialLocation: AccountSetupRoutes.enterName,
      routes: [
        GoRoute(
          path: AccountSetupRoutes.enterName,
          builder: (context, state) => const EnterNamePage(),
        ),
        GoRoute(
          path: AccountSetupRoutes.getNotified,
          builder: (context, state) => const GetNotifiedPage(),
        ),
      ],
    );

    Future<void> pumpAtEnterName(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _withCubit(
          MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a valid name navigates to the Get Notified screen', (
      tester,
    ) async {
      await pumpAtEnterName(tester);

      await tester.enterText(find.byType(TextField), 'Mohamed Shahat');
      await tester.pump();
      await tester.tap(_nextButtonFinder());
      await tester.pumpAndSettle();

      expect(find.byType(GetNotifiedPage), findsOneWidget);
      expect(find.byType(EnterNamePage), findsNothing);
    });

    testWidgets(
      'the entered name is retained in AccountSetupCubit for a later stage',
      (tester) async {
        final cubit = _newCubit();
        await tester.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: buildRouter(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Mohamed Shahat');
        await tester.pump();
        await tester.tap(_nextButtonFinder());
        await tester.pumpAndSettle();

        expect(cubit.state.name, 'Mohamed Shahat');
      },
    );

    testWidgets('back pops to the previous screen', (tester) async {
      await pumpAtEnterName(tester);

      await tester.enterText(find.byType(TextField), 'Mohamed Shahat');
      await tester.pump();
      await tester.tap(_nextButtonFinder());
      await tester.pumpAndSettle();
      expect(find.byType(GetNotifiedPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.byType(GetNotifiedPage), findsNothing);
      expect(find.byType(EnterNamePage), findsOneWidget);
    });
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await pumpOAuth(
      tester,
      _withCubit(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: EnterNamePage(),
        ),
      ),
    );

    expect(find.text('enter_name.title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
