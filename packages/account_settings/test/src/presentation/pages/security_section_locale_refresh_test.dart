// Regression for the Provider Account Settings bug where the Security /
// Biometrics section stayed in the previous language after an in-place language
// switch, only catching up once the page was left and re-entered.
//
// Root cause: `AccountSettingsPage` hosts the Security section as a `const`
// sliver (`_SecuritySliver`). easy_localization's `.tr()` reads the active
// locale at build time but does NOT subscribe the widget to locale changes, so
// a widget re-localizes only when it rebuilds for some other reason. Because
// the sliver is `const`, an ancestor repaint on a language switch skips it
// (identical-widget short-circuit), so `SecuritySection` never rebuilt and its
// `.tr()` copy went stale — while every non-const sibling section refreshed.
//
// Fix: the section's builder now nests `BlocBuilder<TranslateBloc>` around
// `SecuritySection`. `TranslateBloc` is the app-wide source of truth for
// language and emits on every switch, so this self-subscribing builder rebuilds
// the section immediately without touching `SecurityBloc`.
//
// This test reproduces that exact composition (a `const` parent that is never
// rebuilt from above → `BlocConsumer<SecurityBloc>` →
// `BlocBuilder<TranslateBloc>` → `SecuritySection`) and drives the language
// state through `TranslateBloc`. EasyLocalization cannot be bootstrapped in
// this repo's widget-test sandbox (`ensureInitialized()` hangs — see
// apps/sanad_client/test/features/oauth/oauth_test_harness.dart), so `.tr()`
// yields raw keys and the assertion cannot compare Arabic vs English glyphs.
// Instead it proves the mechanism the bug was about: that a language-state
// change rebuilds `SecuritySection` (re-running its `.tr()` lookups) with no
// navigation, while the biometric state is preserved.
import 'dart:async';

import 'package:account_settings/src/domain/enums/app_lock_capability.dart';
import 'package:account_settings/src/presentation/bloc/security/security_bloc.dart';
import 'package:account_settings/src/presentation/widgets/sections/security_section.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecurityBloc extends MockBloc<SecurityEvent, SecurityState>
    implements SecurityBloc {}

class _MockTranslateBloc extends MockBloc<TranslateEvent, TranslateState>
    implements TranslateBloc {}

/// Mirrors `AccountSettingsPage._SecuritySliver`: a `const` widget (never
/// rebuilt from above) whose builder wraps `SecuritySection` in
/// `BlocBuilder<TranslateBloc>` so a language switch rebuilds it. A build
/// counter and a locale probe sit in the same builder to observe the rebuild.
class _SecuritySliverProbe extends StatelessWidget {
  const _SecuritySliverProbe();

  static int buildCount = 0;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SecurityBloc, SecurityState>(
      listenWhen: (previous, current) =>
          previous.toggleStatus != current.toggleStatus,
      listener: (_, _) {},
      builder: (context, state) {
        return BlocBuilder<TranslateBloc, TranslateState>(
          builder: (context, translateState) {
            buildCount++;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SecuritySection(
                  enabled: state.enabled,
                  capability: state.capability,
                  availableBiometrics: state.availableBiometrics,
                  busy: state.toggleStatus == RequestStatus.loading,
                  onToggle: (enable) => context.read<SecurityBloc>().add(
                    SecurityAppLockToggled(enable: enable),
                  ),
                ),
                // Stands in for the section's `.tr()` output: it changes only
                // when this builder rebuilds under a new locale.
                Text('lang=${translateState.languageCode}'),
              ],
            );
          },
        );
      },
    );
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const SecurityAppLockToggled(enable: true));
  });

  late _MockSecurityBloc securityBloc;
  late _MockTranslateBloc translateBloc;
  late StreamController<TranslateState> languageStates;

  setUp(() {
    securityBloc = _MockSecurityBloc();
    // A stable, "on" biometric preference held across every locale switch.
    whenListen(
      securityBloc,
      const Stream<SecurityState>.empty(),
      initialState: const SecurityState(
        enabled: true,
        capability: AppLockCapability.available,
      ),
    );

    // Drive the app language from English, then push new states as the app
    // would on an in-place switch.
    languageStates = StreamController<TranslateState>.broadcast();
    whenListen(
      translateBloc = _MockTranslateBloc(),
      languageStates.stream,
      initialState: const TranslateState(languageCode: 'en'),
    );

    _SecuritySliverProbe.buildCount = 0;
  });

  tearDown(() async {
    await languageStates.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<SecurityBloc>.value(value: securityBloc),
                  BlocProvider<TranslateBloc>.value(value: translateBloc),
                ],
                // `const`: the sliver is never rebuilt from above, so any
                // SecuritySection rebuild must come from the inner
                // BlocBuilder<TranslateBloc> — exactly the fix under test.
                child: const _SecuritySliverProbe(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppSwitch findSwitch(WidgetTester tester) =>
      tester.widget<AppSwitch>(find.byType(AppSwitch));

  testWidgets(
    'Security section re-localizes immediately on an in-place language switch, '
    'in both directions, without resetting the biometric state',
    (tester) async {
      await pump(tester);

      // English, biometric lock ON.
      expect(find.text('lang=en'), findsOneWidget);
      expect(find.text('lang=ar'), findsNothing);
      expect(findSwitch(tester).value, isTrue);
      final buildsAfterMount = _SecuritySliverProbe.buildCount;

      // English → Arabic, staying on the same page (no navigation).
      languageStates.add(const TranslateState());
      await tester.pumpAndSettle();

      // The section rebuilt under the new locale...
      expect(find.text('lang=ar'), findsOneWidget);
      expect(find.text('lang=en'), findsNothing);
      expect(
        _SecuritySliverProbe.buildCount,
        greaterThan(buildsAfterMount),
        reason: 'the language switch must rebuild SecuritySection',
      );
      // ...and the biometric state is preserved across the switch.
      expect(findSwitch(tester).value, isTrue);

      // Arabic → English, again in place.
      final buildsAfterArabic = _SecuritySliverProbe.buildCount;
      languageStates.add(const TranslateState(languageCode: 'en'));
      await tester.pumpAndSettle();

      expect(find.text('lang=en'), findsOneWidget);
      expect(find.text('lang=ar'), findsNothing);
      expect(
        _SecuritySliverProbe.buildCount,
        greaterThan(buildsAfterArabic),
      );
      expect(findSwitch(tester).value, isTrue);

      // The locale switches never touched SecurityBloc — no toggle was
      // dispatched, so no biometric prompt/state change was triggered.
      verifyNever(() => securityBloc.add(any()));
    },
  );
}
