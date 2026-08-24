import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:mocktail/mocktail.dart';

/// Test-only [SessionManager] mock — register/unregister around each test
/// via [registerFakeSessionManager]/[unregisterFakeSessionManager] so
/// widgets that read `sl<SessionManager>().profile` (e.g.
/// `ProviderBranchesPage`) resolve without needing the full auth DI graph.
class MockSessionManager extends Mock implements SessionManager {}

/// Registers a [MockSessionManager] stubbed to return [profile]. Safe to
/// call again mid-test to swap the profile (e.g. simulating a different
/// organization signing in) — replaces any previous registration. Call
/// [unregisterFakeSessionManager] in `tearDown`.
MockSessionManager registerFakeSessionManager({AuthProfileEntity? profile}) {
  unregisterFakeSessionManager();
  final session = MockSessionManager();
  when(() => session.profile).thenReturn(profile);
  sl.registerSingleton<SessionManager>(session);
  return session;
}

void unregisterFakeSessionManager() {
  if (sl.isRegistered<SessionManager>()) {
    sl.unregister<SessionManager>();
  }
}
