import 'package:app_animations/app_animations.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:easy_localization/src/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/otp.dart';

/// easy_localization is not initialised in these tests, so `.tr()` returns the
/// key itself. Assertions therefore target keys, not copy — they verify
/// wiring, not translations.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  OtpVisualStyle? appStyle,
}) async {
  // `AppTheme.light()` reads ScreenUtil, so it must be built inside the
  // ScreenUtilInit builder, not hoisted out of it.
  Widget build() {
    final Widget app = MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
    return appStyle == null ? app : OtpStyleScope(style: appStyle, child: app);
  }

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      builder: (_, _) => build(),
    ),
  );
  await tester.pump();
}

OtpFlowConfig<String> _config({
  TaskEither<Failure, OtpDelivery> Function()? onRequest,
  TaskEither<Failure, OtpCooldown> Function()? onCooldown,
  TaskEither<Failure, String> Function(String code)? onVerify,
  bool autoSubmit = true,
  bool showSuccessScreen = false,
  OtpVisualStyle? style,
}) => OtpFlowConfig<String>.email(
  destination: 'user@example.com',
  autoSubmit: autoSubmit,
  showSuccessScreen: showSuccessScreen,
  style: style,
  verifier: CallbackOtpVerifier<String>(
    onRequestCode: onRequest ?? () => TaskEither.right(const OtpDelivery()),
    onCooldown: onCooldown ?? () => TaskEither.right(OtpCooldown.unknown),
    onVerifyCode: onVerify ?? (_) => TaskEither.right('session-123456'),
  ),
);

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(EditableText).first, code);
  await tester.pump();
}

/// Matches the resends-left caption whichever plural case resolves.
final Finder _resendsLeftText = find.byWidgetPredicate(
  (w) => w is Text && (w.data?.startsWith('otp.resends_left') ?? false),
);

void main() {
  setUpAll(() {
    // Unlike `.tr()`, `plural()` has no key fallback — it reads the locale off
    // the Localization singleton and throws when none is loaded. No
    // translations are supplied, so it still resolves to the raw key.
    Localization.load(const Locale('en', 'US'));
  });

  group('OtpHost', () {
    testWidgets(
      "the client spec's icon container wraps only the icon at its designed "
      '56dp size, not stretched full-width by the stretch-aligned parent '
      'Column (regression)',
      (tester) async {
        await _pump(
          tester,
          OtpHost<String>(
            config: _config(style: OtpVisualStyle.client),
            onResult: (_) {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // AppRadius.circularXl appears exactly once in the client layout, on
        // the icon circle — a unique, stable way to find it without depending
        // on the private `_OtpIcon` class name from outside the library.
        final iconContainer = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).borderRadius ==
                  AppRadius.circularXl,
        );
        expect(iconContainer, findsOneWidget);

        final size = tester.getSize(iconContainer);
        // responsiveDimension() clamps its result to at most 2.5x the base
        // value passed in, so a correctly-sized 56dp icon can never exceed
        // 140 regardless of the test window's width. The pre-fix bug
        // stretched this to the full ~800px test-window width via the
        // parent Column's crossAxisAlignment.stretch — nowhere near that
        // clamp.
        expect(size.width, lessThan(200));
        expect(
          size.width,
          closeTo(size.height, 1),
          reason: 'must stay a square circle, not a wide bar',
        );
      },
    );

    testWidgets(
      'the destination is wrapped in an LTR isolate so a `+`-prefixed phone '
      'reads left-to-right under an RTL layout (SAN-770: the `+` was drawn at '
      'the end of the number)',
      (tester) async {
        // U+2066 LEFT-TO-RIGHT ISOLATE … U+2069 POP DIRECTIONAL ISOLATE.
        const isolated = '\u{2066}+971585555552\u{2069}';
        await _pump(
          tester,
          Directionality(
            textDirection: TextDirection.rtl,
            child: OtpHost<String>(
              config: OtpFlowConfig<String>.phone(
                destination: '+971585555552',
                verifier: CallbackOtpVerifier<String>(
                  onRequestCode: () => TaskEither.right(const OtpDelivery()),
                  onCooldown: () => TaskEither.right(OtpCooldown.unknown),
                  onVerifyCode: (_) => TaskEither.right('session-123456'),
                ),
              ),
              onResult: (_) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          find.textContaining(isolated, findRichText: true),
          findsOneWidget,
        );
      },
    );

    testWidgets('verifies a code and reports the payload', (tester) async {
      OtpResult<String>? result;
      await _pump(
        tester,
        OtpHost<String>(
          config: _config(),
          onResult: (r) => result = r,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await _enterCode(tester, '123456');
      await tester.pump(const Duration(milliseconds: 50));

      expect(result, isA<OtpVerified<String>>());
      expect((result! as OtpVerified<String>).data, 'session-123456');
    });

    testWidgets('shows an inline error for an invalid code and stays open', (
      tester,
    ) async {
      OtpResult<String>? result;
      await _pump(
        tester,
        OtpHost<String>(
          config: _config(
            onVerify: (_) =>
                TaskEither.left(const ValidationFailure(message: 'nope')),
          ),
          onResult: (r) => result = r,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await _enterCode(tester, '123456');
      await tester.pump(const Duration(milliseconds: 50));

      expect(result, isNull);
      expect(find.text('otp.invalid_code'.tr()), findsOneWidget);
    });

    testWidgets(
      'a rejected code reported as a plain business-rule failure (a '
      'hand-written backend rejection, not a class-validator array) still '
      'shows the inline field error, not the dispatch banner (regression)',
      (tester) async {
        OtpResult<String>? result;
        await _pump(
          tester,
          OtpHost<String>(
            config: _config(
              onVerify: (_) => TaskEither.left(
                const BusinessRuleFailure(message: 'Invalid code'),
              ),
            ),
            onResult: (r) => result = r,
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        await _enterCode(tester, '123456');
        await tester.pump(const Duration(milliseconds: 50));

        expect(result, isNull);
        expect(find.text('otp.invalid_code'.tr()), findsOneWidget);
        expect(
          find.text('Invalid code'),
          findsNothing,
          reason: 'the raw failure message must not leak into a banner',
        );
      },
    );

    testWidgets(
      'a live server cooldown renders a countdown and NO error '
      '(regression: reopening inside a cooldown showed an error under an '
      'empty field)',
      (tester) async {
        var requested = false;
        await _pump(
          tester,
          OtpHost<String>(
            config: _config(
              style: OtpVisualStyle.client,
              onRequest: () {
                requested = true;
                return TaskEither.right(const OtpDelivery());
              },
              onCooldown: () => TaskEither.right(
                const OtpCooldown(canResend: false, remainingSeconds: 90),
              ),
            ),
            onResult: (_) {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(requested, isFalse, reason: 'no send, so no 429 to surface');
        // No EasyLocalization bootstrap, so `.tr(namedArgs: ...)` on an
        // unresolved key returns the raw key untouched (no "{time}" to
        // substitute in it) — see `OtpCountdown`.
        expect(find.text('otp.client.resend_countdown'.tr()), findsOneWidget);
        expect(find.text('otp.client.invalid_code'.tr()), findsNothing);
        expect(find.text('otp.expired_code'.tr()), findsNothing);
      },
    );

    testWidgets('a delivery failure renders in the banner with a retry', (
      tester,
    ) async {
      await _pump(
        tester,
        OtpHost<String>(
          config: _config(
            onRequest: () =>
                TaskEither.left(const ConflictFailure(message: 'Taken')),
          ),
          onResult: (_) {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Taken'), findsOneWidget);
      expect(find.text('otp.retry'.tr()), findsOneWidget);
      // A delivery problem is never a field error.
      expect(find.text('otp.invalid_code'.tr()), findsNothing);
    });

    testWidgets(
      'under the client spec the countdown and resend link are mutually '
      'exclusive (Figma 6979:27634 vs 6979:27585/7063:25563)',
      (tester) async {
        await _pump(
          tester,
          OtpHost<String>(
            config: _config(
              style: OtpVisualStyle.client,
              onCooldown: () => TaskEither.right(
                const OtpCooldown(canResend: false, remainingSeconds: 30),
              ),
            ),
            onResult: (_) {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // While the countdown runs, only the countdown text shows — the
        // resend row is not rendered at all, not merely disabled.
        expect(
          find.textContaining(
            'otp.client.not_received'.tr(),
            findRichText: true,
          ),
          findsNothing,
        );
        expect(find.text('otp.client.resend_countdown'.tr()), findsOneWidget);
      },
    );

    testWidgets(
      'under the client spec, once the cooldown reaches zero the resend link '
      'replaces the countdown (Figma 6979:27585 / 7063:25563)',
      (tester) async {
        await _pump(
          tester,
          OtpHost<String>(
            config: _config(
              style: OtpVisualStyle.client,
              onCooldown: () => TaskEither.right(OtpCooldown.unknown),
            ),
            onResult: (_) {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          find.textContaining(
            'otp.client.not_received'.tr(),
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(find.text('otp.client.resend_countdown'.tr()), findsNothing);
      },
    );

    testWidgets('a 409 on verify closes the flow with OtpFailed', (
      tester,
    ) async {
      OtpResult<String>? result;
      await _pump(
        tester,
        OtpHost<String>(
          config: _config(
            onVerify: (_) =>
                TaskEither.left(const ConflictFailure(message: 'Claimed')),
          ),
          onResult: (r) => result = r,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await _enterCode(tester, '123456');
      await tester.pump(const Duration(milliseconds: 50));

      expect(result, isA<OtpFailed<String>>());
    });

    testWidgets(
      'by default renders no staggered entrance (provider path unchanged)',
      (tester) async {
        await _pump(
          tester,
          OtpHost<String>(config: _config(), onResult: (_) {}),
        );

        expect(find.byType(AppStaggeredColumn), findsNothing);
      },
    );

    // ── Client vs provider visual separation ───────────────────────────────
    //
    // The regression these lock down: both apps rendered one hardcoded
    // layout, so tuning the client OTP screen silently restyled the
    // provider's. Each group asserts a trait its own Figma has and the other
    // Figma explicitly does not.

    testWidgets(
      'the provider spec renders no icon circle, and shows the countdown and '
      'the resend row together (Figma 3809:18083 / 2142:14121)',
      (tester) async {
        await _pump(
          tester,
          OtpHost<String>(
            config: _config(
              style: OtpVisualStyle.provider,
              onCooldown: () => TaskEither.right(
                const OtpCooldown(canResend: false, remainingSeconds: 90),
              ),
            ),
            onResult: (_) {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // The client screen's icon circle must not appear here.
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration! as BoxDecoration).borderRadius ==
                    AppRadius.circularXl,
          ),
          findsNothing,
        );

        // Unlike the client spec these coexist: a bare mm:ss countdown with
        // the (greyed-out) resend row still below it.
        expect(find.text('01:30'), findsOneWidget);
        expect(
          find.textContaining('otp.send_again'.tr(), findRichText: true),
          findsOneWidget,
        );
        // ...and none of the client screen's own copy leaks in.
        expect(find.text('otp.client.resend_countdown'.tr()), findsNothing);
      },
    );

    testWidgets(
      'the provider spec draws larger cells than the client spec — a client '
      'restyle cannot resize the provider field (regression)',
      (tester) async {
        Future<double> cellWidth(OtpVisualStyle style) async {
          await _pump(
            tester,
            OtpHost<String>(
              config: _config(style: style),
              onResult: (_) {},
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          return tester.getSize(find.byKey(otpCellKey(0))).width;
        }

        final client = await cellWidth(OtpVisualStyle.client);
        final provider = await cellWidth(OtpVisualStyle.provider);

        expect(
          provider,
          greaterThan(client),
          reason:
              'provider cells are 54.5dp, client cells 45dp at the '
              'designed width; a narrow screen scales both rows down '
              'proportionally (covered in app_otp_field_test.dart)',
        );
      },
    );

    testWidgets(
      'an app-level OtpStyleScope selects the layout for a flow that names no '
      'style of its own — this is what lets the OTP call sites inside shared '
      'packages render each app design',
      (tester) async {
        await _pump(
          tester,
          OtpHost<String>(config: _config(), onResult: (_) {}),
          appStyle: OtpVisualStyle.client,
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('otp.client.title'.tr()), findsOneWidget);
        expect(find.text('otp.title'.tr()), findsNothing);
      },
    );

    testWidgets('a config style overrides the app-level scope', (tester) async {
      await _pump(
        tester,
        OtpHost<String>(
          config: _config(style: OtpVisualStyle.provider),
          onResult: (_) {},
        ),
        appStyle: OtpVisualStyle.client,
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('otp.title'.tr()), findsOneWidget);
      expect(find.text('otp.client.title'.tr()), findsNothing);
    });

    testWidgets(
      'with no scope and no config style the provider spec applies — the copy '
      'the shared `otp.*` keys were written against',
      (tester) async {
        await _pump(
          tester,
          OtpHost<String>(config: _config(), onResult: (_) {}),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('otp.title'.tr()), findsOneWidget);
      },
    );

    testWidgets('animateContent wraps the content in a staggered entrance', (
      tester,
    ) async {
      final config = OtpFlowConfig<String>.email(
        destination: 'user@example.com',
        animateContent: true,
        verifier: CallbackOtpVerifier<String>(
          onRequestCode: () => TaskEither.right(const OtpDelivery()),
          onCooldown: () => TaskEither.right(OtpCooldown.unknown),
          onVerifyCode: (_) => TaskEither.right('session-123456'),
        ),
      );

      await _pump(tester, OtpHost<String>(config: config, onResult: (_) {}));

      expect(find.byType(AppStaggeredColumn), findsOneWidget);
      // Bounded pumps only (repeating caret) — no pending timer must surface.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 350));
    });

    // The server's `attemptsLeft` was carried on the state but rendered
    // nowhere, so an OTP screen could never tell the user how many resends
    // were left.
    for (final style in OtpVisualStyle.values) {
      testWidgets('${style.name}: renders the resends the server reports', (
        tester,
      ) async {
        await _pump(
          tester,
          OtpHost<String>(
            config: _config(
              style: style,
              onCooldown: () => TaskEither.right(
                const OtpCooldown(
                  canResend: true,
                  remainingSeconds: 0,
                  resendsLeft: 3,
                ),
              ),
            ),
            onResult: (_) {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(_resendsLeftText, findsOneWidget);
      });

      testWidgets('${style.name}: says nothing when the count is unreported', (
        tester,
      ) async {
        await _pump(
          tester,
          OtpHost<String>(
            // `OtpCooldown.unknown` carries the -1 sentinel.
            config: _config(style: style),
            onResult: (_) {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(_resendsLeftText, findsNothing);
      });
    }
  });
}
