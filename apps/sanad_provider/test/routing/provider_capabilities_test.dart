import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_provider/src/routing/provider_capabilities.dart';

class _MockSessionManager extends Mock implements SessionManager {}

void main() {
  group('ProviderCapabilities.canManageOrganization', () {
    test('true for an organization/company provider (isCompany)', () {
      final session = _MockSessionManager();
      when(() => session.isCompany).thenReturn(true);

      expect(session.canManageOrganization, isTrue);
    });

    test('false for an individual provider', () {
      final session = _MockSessionManager();
      when(() => session.isCompany).thenReturn(false);

      expect(session.canManageOrganization, isFalse);
    });
  });
}
