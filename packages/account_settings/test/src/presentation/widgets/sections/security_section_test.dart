import 'package:account_settings/src/domain/enums/app_lock_capability.dart';
import 'package:account_settings/src/presentation/widgets/sections/security_section.dart';
import 'package:design_system/design_system.dart';
import 'package:device/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // EasyLocalization is deliberately not bootstrapped, so `.tr()` yields the
  // raw key — assertions target keys and widget state, not display copy.
  const captionFace = 'settings.app_lock_caption_face';
  const captionFingerprint = 'settings.app_lock_caption_fingerprint';
  const captionGeneric = 'settings.app_lock_caption_generic';
  const captionUnsupported = 'settings.app_lock_caption_unsupported';

  Future<void> pumpSection(
    WidgetTester tester, {
    bool enabled = false,
    AppLockCapability capability = AppLockCapability.available,
    List<BiometricType> availableBiometrics = const [],
    bool busy = false,
    ValueChanged<bool>? onToggle,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            // Mirrors the real page, which hosts the section inside
            // AppScrollPage's slivers rather than a fixed-height box.
            body: SingleChildScrollView(
              child: SecuritySection(
                enabled: enabled,
                capability: capability,
                availableBiometrics: availableBiometrics,
                busy: busy,
                onToggle: onToggle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppSwitch findSwitch(WidgetTester tester) =>
      tester.widget<AppSwitch>(find.byType(AppSwitch));

  testWidgets('renders a switch row reflecting the stored preference', (
    tester,
  ) async {
    await pumpSection(tester, enabled: true);

    expect(find.byType(AppSwitch), findsOneWidget);
    expect(findSwitch(tester).value, isTrue);
  });

  testWidgets('an in-flight toggle spins without moving the switch', (
    tester,
  ) async {
    await pumpSection(tester, busy: true);

    final appSwitch = findSwitch(tester);
    expect(appSwitch.loading, isTrue);
    // Still showing the previous value: the user must not see a state the OS
    // has not yet approved.
    expect(appSwitch.value, isFalse);
  });

  testWidgets('reports the toggle request to the caller', (tester) async {
    bool? requested;
    await pumpSection(tester, onToggle: (value) => requested = value);

    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();

    expect(requested, isTrue);
  });

  testWidgets('an unsupported device leaves the switch inert', (tester) async {
    var called = false;
    await pumpSection(
      tester,
      capability: AppLockCapability.unsupported,
      onToggle: (_) => called = true,
    );

    expect(find.text(captionUnsupported), findsOneWidget);
    expect(findSwitch(tester).onChanged, isNull);

    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(called, isFalse);
  });

  group('caption wording follows the enrolled method', () {
    testWidgets('Face ID', (tester) async {
      await pumpSection(
        tester,
        availableBiometrics: const [BiometricType.face],
      );
      expect(find.text(captionFace), findsOneWidget);
    });

    testWidgets('fingerprint', (tester) async {
      await pumpSection(
        tester,
        availableBiometrics: const [BiometricType.fingerprint],
      );
      expect(find.text(captionFingerprint), findsOneWidget);
    });

    testWidgets('no enrolled biometric still offers the lock via passcode', (
      tester,
    ) async {
      await pumpSection(tester, onToggle: (_) {});

      // Supported-but-not-enrolled is NOT a blocked state: the device
      // credential is an acceptable credential, so the row stays usable.
      expect(find.text(captionGeneric), findsOneWidget);
      expect(findSwitch(tester).onChanged, isNotNull);
    });
  });
}
