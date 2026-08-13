// See workers/test/src/presentation/widgets/worker_list_item_test.dart for
// why EasyLocalization is not bootstrapped here (`.tr()` falls back to the
// raw key — fine, since this test asserts on the DATA values, not labels).
import 'package:account_settings/src/presentation/widgets/sections/account_credentials_section.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _surfaceSize = Size(900, 1200);

Future<void> _pump(
  WidgetTester tester, {
  String? name,
  String? phone,
  String? email,
  bool emailVerified = false,
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
          body: AccountCredentialsSection(
            name: name,
            phone: phone,
            email: email,
            emailVerified: emailVerified,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'renders the name/phone/email values passed in from state — '
    'regression for the reported empty-fields symptom against the exact '
    'production GET /service-provider/profile fixture',
    (tester) async {
      await _pump(
        tester,
        name: 'Layla Al Mansoori',
        phone: '+971501234567',
        email: 'seed-company-provider-1@sanad.test',
        emailVerified: true,
      );

      expect(find.text('Layla Al Mansoori'), findsOneWidget);
      // UaePhoneValidator.toNationalInput('+971501234567') == '501234567'.
      expect(find.text('501234567'), findsOneWidget);
      expect(
        find.text('seed-company-provider-1@sanad.test'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'renders blank fields when name/phone/email are genuinely null — '
    'the pre-refresh/no-data state, not a bug',
    (tester) async {
      await _pump(tester);

      expect(find.text('Layla Al Mansoori'), findsNothing);
      expect(find.text('501234567'), findsNothing);
    },
  );

  testWidgets(
    'updates the displayed values when the background refresh populates '
    'previously-null state — reproduces the reported sequence: cold seed '
    '(session has no accountSettings yet) rebuilt once the persona-profile '
    'refresh completes, same widget instance, no key change',
    (tester) async {
      await _pump(tester); // cold seed: settings == null
      expect(find.text('Layla Al Mansoori'), findsNothing);

      // Same tree shape/position/type/no keys — this must hit
      // didUpdateWidget on the SAME State, exactly like AccountSettingsPage's
      // BlocBuilder rebuilding AccountCredentialsSection after the bloc
      // re-emits with server data.
      await _pump(
        tester,
        name: 'Layla Al Mansoori',
        phone: '+971501234567',
        email: 'seed-company-provider-1@sanad.test',
        emailVerified: true,
      );

      expect(find.text('Layla Al Mansoori'), findsOneWidget);
      expect(find.text('501234567'), findsOneWidget);
      expect(
        find.text('seed-company-provider-1@sanad.test'),
        findsOneWidget,
      );
    },
  );
}
