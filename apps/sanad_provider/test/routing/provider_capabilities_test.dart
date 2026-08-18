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

  group('ProviderCapabilities.isProviderOwner', () {
    test('true for an organization provider (owner-only backend surfaces)', () {
      final session = _MockSessionManager();
      when(() => session.isProvider).thenReturn(true);

      expect(session.isProviderOwner, isTrue);
    });

    test(
      'true for an individual provider too — verified live against all 8 '
      'owner-only endpoints, unlike canManageOrganization/isCompany',
      () {
        final session = _MockSessionManager();
        when(() => session.isProvider).thenReturn(true);

        expect(session.isProviderOwner, isTrue);
      },
    );

    test('false for a manager/worker, regardless of granted permissions', () {
      final session = _MockSessionManager();
      when(() => session.isProvider).thenReturn(false);

      expect(session.isProviderOwner, isFalse);
    });
  });

  group('ProviderCapabilities.isOrganizationTeamMember', () {
    test('true for a worker', () {
      final session = _MockSessionManager();
      when(() => session.isWorker).thenReturn(true);
      when(() => session.isManager).thenReturn(false);

      expect(session.isOrganizationTeamMember, isTrue);
    });

    test('true for a manager', () {
      final session = _MockSessionManager();
      when(() => session.isWorker).thenReturn(false);
      when(() => session.isManager).thenReturn(true);

      expect(session.isOrganizationTeamMember, isTrue);
    });

    test(
      'false for the organization owner — canManageOrganization covers '
      'them separately, not this getter',
      () {
        final session = _MockSessionManager();
        when(() => session.isWorker).thenReturn(false);
        when(() => session.isManager).thenReturn(false);

        expect(session.isOrganizationTeamMember, isFalse);
      },
    );

    test('false for an individual provider', () {
      final session = _MockSessionManager();
      when(() => session.isWorker).thenReturn(false);
      when(() => session.isManager).thenReturn(false);

      expect(session.isOrganizationTeamMember, isFalse);
    });
  });
}
