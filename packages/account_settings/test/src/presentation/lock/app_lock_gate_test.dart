import 'dart:async';

import 'package:account_settings/src/domain/enums/app_lock_capability.dart';
import 'package:account_settings/src/domain/enums/app_lock_state.dart';
import 'package:account_settings/src/domain/repositories/app_lock_repository.dart';
import 'package:account_settings/src/presentation/lock/app_lock_controller.dart';
import 'package:account_settings/src/presentation/lock/app_lock_gate.dart';
import 'package:account_settings/src/presentation/lock/app_lock_screen.dart';
import 'package:auth/auth.dart';
import 'package:device/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AppLockRepository {}

class _MockBiometricService extends Mock implements BiometricService {}

class _MockSessionManager extends Mock implements SessionManager {}

class _MockSession extends Mock implements AuthSessionEntity {}

/// Stands in for the routed app. If this ever appears while the gate is shut,
/// protected content has leaked past the lock.
class _ProtectedApp extends StatelessWidget {
  const _ProtectedApp();

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: Scaffold(body: Text('PROTECTED')));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepository repository;
  late _MockBiometricService biometrics;
  late _MockSessionManager sessionManager;
  late ValueNotifier<AuthSessionEntity?> sessionNotifier;

  // EasyLocalization is deliberately not bootstrapped, so `.tr()` yields the
  // raw key — which makes it a stable finder.
  const unlockLabel = 'settings.app_lock_screen_unlock';

  AppLockController buildController() => AppLockController(
    repository: repository,
    biometrics: biometrics,
    sessionManager: sessionManager,
    featureEnabled: true,
  );

  void stubAuth(BiometricAuthStatus status) {
    when(
      () => biometrics.authenticate(
        reason: any(named: 'reason'),
        biometricOnly: any(named: 'biometricOnly'),
      ),
    ).thenAnswer((_) async => BiometricAuthResult(status: status));
  }

  /// Mirrors the real tree: in both apps the gate sits inside `ScreenUtilInit`,
  /// which `AppTheme` needs in order to scale typography.
  Future<void> pumpGate(
    WidgetTester tester,
    AppLockController controller,
  ) async {
    // Match the apps' design size so text scales the way it does on device.
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    return tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        builder: (_, _) => AppLockGate(
          controller: controller,
          onLogout: () async {},
          child: const _ProtectedApp(),
        ),
      ),
    );
  }

  setUp(() {
    repository = _MockRepository();
    biometrics = _MockBiometricService();
    sessionManager = _MockSessionManager();
    sessionNotifier = ValueNotifier<AuthSessionEntity?>(_MockSession());

    when(() => sessionManager.watch()).thenReturn(sessionNotifier);
    when(
      () => sessionManager.current(),
    ).thenAnswer((_) => sessionNotifier.value);
    when(repository.isEnabled).thenAnswer((_) async => true);
    when(
      repository.capability,
    ).thenAnswer((_) async => AppLockCapability.available);
    when(
      () => repository.setEnabled(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    stubAuth(BiometricAuthStatus.failed);
  });

  tearDown(() => sessionNotifier.dispose());

  testWidgets('protected content never builds while the gate is shut', (
    tester,
  ) async {
    final controller = buildController();
    await pumpGate(tester, controller);
    await tester.pumpAndSettle();

    expect(controller.state, AppLockState.locked);
    // Not "is offscreen" or "is covered": the routed subtree is not in the
    // tree at all.
    expect(find.text('PROTECTED'), findsNothing);
    expect(find.byType(AppLockScreen), findsOneWidget);
  });

  testWidgets('nothing renders before the gate has decided', (tester) async {
    // A capability probe that never completes holds the controller in
    // AppLockState.unknown for the whole test.
    when(
      repository.capability,
    ).thenAnswer((_) => Completer<AppLockCapability>().future);

    final controller = buildController();
    await pumpGate(tester, controller);
    await tester.pump();

    expect(controller.state, AppLockState.unknown);
    expect(find.text('PROTECTED'), findsNothing);
    // Not the lock screen either — we have not yet established that there is
    // anything to lock, and guessing either way would be wrong.
    expect(find.byType(AppLockScreen), findsNothing);
  });

  testWidgets('a successful unlock reveals the routed app', (tester) async {
    stubAuth(BiometricAuthStatus.success);
    final controller = buildController();

    await pumpGate(tester, controller);
    await tester.pumpAndSettle();

    expect(controller.state, AppLockState.unlocked);
    expect(find.text('PROTECTED'), findsOneWidget);
    expect(find.byType(AppLockScreen), findsNothing);
  });

  testWidgets('the gate does not auto-retry after a failure', (tester) async {
    final controller = buildController();
    await pumpGate(tester, controller);
    await tester.pumpAndSettle();

    // One prompt from arming, and none since — a self-retrying gate would
    // trap the user in a loop of prompts they cannot dismiss.
    verify(
      () => biometrics.authenticate(
        reason: any(named: 'reason'),
        biometricOnly: any(named: 'biometricOnly'),
      ),
    ).called(1);
    expect(controller.state, AppLockState.locked);
  });

  testWidgets('tapping Unlock re-raises the prompt and can open the gate', (
    tester,
  ) async {
    final controller = buildController();
    await pumpGate(tester, controller);
    await tester.pumpAndSettle();
    stubAuth(BiometricAuthStatus.success);

    // The lock screen scrolls, so the button may sit below the fold at large
    // text scales — scroll it into view before tapping.
    await tester.ensureVisible(find.text(unlockLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(unlockLabel));
    await tester.pumpAndSettle();

    expect(controller.state, AppLockState.unlocked);
    expect(find.text('PROTECTED'), findsOneWidget);
  });

  testWidgets('an unsupported device fails open and shows the routed app', (
    tester,
  ) async {
    when(
      repository.capability,
    ).thenAnswer((_) async => AppLockCapability.unsupported);

    final controller = buildController();
    await pumpGate(tester, controller);
    await tester.pumpAndSettle();

    expect(controller.state, AppLockState.unavailable);
    expect(find.text('PROTECTED'), findsOneWidget);
  });

  testWidgets('a session cleared while locked opens the gate', (tester) async {
    final controller = buildController();
    await pumpGate(tester, controller);
    await tester.pumpAndSettle();
    expect(find.byType(AppLockScreen), findsOneWidget);

    sessionNotifier.value = null;
    await tester.pumpAndSettle();

    // No lock screen stranded over a logged-out app.
    expect(find.byType(AppLockScreen), findsNothing);
    expect(find.text('PROTECTED'), findsOneWidget);
  });
}
