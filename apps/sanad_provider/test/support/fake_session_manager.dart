import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:mocktail/mocktail.dart';

/// Test-only [SessionManager] mock — register/unregister around each test
/// via [registerFakeSessionManager]/[unregisterFakeSessionManager] so
/// widgets that read `context.session` resolve without needing the full
/// auth DI graph.
///
/// Mirrors `packages/branches/test/support/fake_session_manager.dart` —
/// duplicated rather than shared because the two live in different packages
/// with no test-only dependency between them.
class MockSessionManager extends Mock implements SessionManager {}

/// Registers a [MockSessionManager] stubbed with [isProvider] (which backs
/// the app-local `SessionManager.isProviderOwner` extension getter) and an
/// optional [displayName]/[businessName] for greeting tests. Safe to call
/// again mid-test — replaces any previous registration. Call
/// [unregisterFakeSessionManager] in `tearDown`.
MockSessionManager registerFakeSessionManager({
  bool isProvider = true,
  String? displayName,
  String? businessName,
}) {
  unregisterFakeSessionManager();
  final session = MockSessionManager();
  when(() => session.isProvider).thenReturn(isProvider);
  when(() => session.displayName).thenReturn(displayName);
  when(() => session.businessName).thenReturn(businessName);
  sl.registerSingleton<SessionManager>(session);
  return session;
}

void unregisterFakeSessionManager() {
  if (sl.isRegistered<SessionManager>()) {
    sl.unregister<SessionManager>();
  }
}
