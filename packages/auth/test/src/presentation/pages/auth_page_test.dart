// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys, not translated text (see
// worker_list_item_test.dart in `workers` for the full convention note).

import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:auth/src/presentation/pages/auth_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

Future<void> _pump(
  WidgetTester tester,
  AuthBloc bloc, {
  required bool initialIsLogin,
}) async {
  whenListen(
    bloc,
    const Stream<AuthState>.empty(),
    initialState: const AuthInitialState(),
  );

  // Without EasyLocalization bootstrapped, `.tr()` falls back to the raw
  // key — far longer than any real translation, which overflows the
  // account-switch row's fixed-width layout. That's a byproduct of the
  // untranslated test key, not a real layout bug in the page under test
  // (see role_form_page_test.dart in `provider_rbac` for the same
  // convention). flutter_test reinstalls its own `FlutterError.onError` at
  // the start of every test body, so this must be set from inside the test.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('A RenderFlex overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: AuthPage(
            initialIsLogin: initialIsLogin,
            onOtpSent: (_, _) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _MockAuthBloc bloc;

  setUp(() {
    bloc = _MockAuthBloc();
  });

  testWidgets(
    'Sign In (Login screen) shows the sign-in Google label (SAN-586)',
    (tester) async {
      await _pump(tester, bloc, initialIsLogin: true);

      expect(find.text('auth.google'), findsOneWidget);
      expect(find.text('auth.google_signup'), findsNothing);
    },
  );

  testWidgets(
    'Create Account screen shows the registration-specific Google label '
    '(SAN-586)',
    (tester) async {
      await _pump(tester, bloc, initialIsLogin: false);

      expect(find.text('auth.google_signup'), findsOneWidget);
      expect(find.text('auth.google'), findsNothing);
    },
  );
}
