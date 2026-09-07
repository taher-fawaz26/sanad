// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, so
// assertions match on raw i18n keys (see oauth_test_harness.dart /
// auth_page_test.dart for the same convention).
//
// These tests pump OAuthOtpPage directly with a fake `CallbackOtpVerifier`,
// exactly as `packages/otp`'s own `otp_host_test.dart` does, exercising the
// widget's rendering + inline-error states in isolation. The verify-result
// routing (ACTIVE → Enter Name / Home, suspended, scheduled) is covered by
// oauth_otp_routing_test.dart, which wires the real service locator.
//
// Uses bounded `tester.pump()` calls throughout, never `pumpAndSettle()`:
// `OtpFlowConfig`'s default `autofocus: true` means the OTP field's caret
// starts blinking (a repeating animation) as soon as the page mounts, and
// `pumpAndSettle()` never returns while one is running (same rule
// `app_otp_field_test.dart` follows for the same caret).

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/otp.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_page.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(theme: AppTheme.light(), home: home),
    ),
  );
  // Settles the cooldown probe without waiting out the caret's indefinite
  // blink.
  await tester.pump(const Duration(milliseconds: 50));
}

OtpFlowConfig<ClientVerifyResult> _config({
  required OtpChannel channel,
  String destination = 'user@example.com',
  TaskEither<Failure, ClientVerifyResult> Function(String code)? onVerify,
}) => buildOAuthOtpConfig(
  channel: channel,
  destination: destination,
  verifier: CallbackOtpVerifier<ClientVerifyResult>(
    onRequestCode: () => TaskEither.right(const OtpDelivery()),
    onCooldown: () => TaskEither.right(OtpCooldown.unknown),
    onVerifyCode:
        onVerify ??
        (_) => TaskEither.right(
          ClientVerifyResult(
            status: AuthAccountStatus.active,
            accessToken: 'a',
            refreshToken: 'r',
            user: const ClientAuthUser(id: 'c', preferredLanguage: 'en'),
          ),
        ),
  ),
);

void main() {
  testWidgets(
    'renders back button, title/subtitle, email destination and Next button',
    (tester) async {
      await _pump(
        tester,
        OAuthOtpPage(config: _config(channel: OtpChannel.email)),
      );

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.text('otp.client.title'.tr()), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains(
                'oauth.otp_subtitle_email'.tr(),
              ) &&
              widget.text.toPlainText().contains('user@example.com'),
        ),
        findsOneWidget,
        reason: 'subtitle + email destination render as one flowing line',
      );
      expect(find.widgetWithText(AppButton, 'oauth.next'.tr()), findsOneWidget);
    },
  );

  testWidgets('renders the phone destination and phone-specific subtitle', (
    tester,
  ) async {
    await _pump(
      tester,
      OAuthOtpPage(
        config: _config(
          channel: OtpChannel.phone,
          destination: '+971501234567',
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains(
              'oauth.otp_subtitle_phone'.tr(),
            ) &&
            widget.text.toPlainText().contains('+971501234567'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an invalid-code failure shows the error under the field, '
      'never a top banner', (tester) async {
    await _pump(
      tester,
      OAuthOtpPage(
        config: _config(
          channel: OtpChannel.email,
          onVerify: (_) =>
              TaskEither.left(const ValidationFailure(message: 'x')),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText).first, '123456');
    await tester.pump();
    // No autoSubmit — the pinned Next button is the only submit trigger.
    await tester.tap(find.widgetWithText(AppButton, 'oauth.next'.tr()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('otp.client.invalid_code'.tr()), findsOneWidget);
    // No dispatch banner container — only the field-level error is present.
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  testWidgets('editing the code after an error clears it (no stale error)', (
    tester,
  ) async {
    await _pump(
      tester,
      OAuthOtpPage(
        config: _config(
          channel: OtpChannel.email,
          onVerify: (_) =>
              TaskEither.left(const ValidationFailure(message: 'x')),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText).first, '123456');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'oauth.next'.tr()));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('otp.client.invalid_code'.tr()), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, '654321');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('otp.client.invalid_code'.tr()), findsNothing);
  });

  testWidgets('tapping back pops the page', (tester) async {
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/otp'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) =>
              OAuthOtpPage(config: _config(channel: OtpChannel.email)),
        ),
      ],
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) =>
            MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(OAuthOtpPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(OAuthOtpPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('renders correctly under RTL', (tester) async {
    await _pump(
      tester,
      Directionality(
        textDirection: TextDirection.rtl,
        child: OAuthOtpPage(config: _config(channel: OtpChannel.email)),
      ),
    );

    expect(find.text('otp.client.title'.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
