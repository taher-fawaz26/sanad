import 'package:flutter_test/flutter_test.dart';
import 'package:invitation/src/domain/entities/invitation_mock.dart';

void main() {
  group('InvitationRole', () {
    test('worker maps to the worker label key', () {
      expect(InvitationRole.worker.labelKey, 'invitation.role_worker');
    });

    test('manager maps to the manager label key', () {
      expect(InvitationRole.manager.labelKey, 'invitation.role_manager');
    });
  });

  group('InvitationMock', () {
    test('sample fixture carries the documented mock values', () {
      const sample = InvitationMock.sample;
      expect(sample.organization, 'Horizon Ventures');
      expect(sample.inviter, 'Mohamed Khaled');
      expect(sample.email, 'john@example.com');
      expect(sample.role, InvitationRole.worker);
    });

    test('supports equality by value', () {
      const a = InvitationMock(
        organization: 'Acme',
        inviter: 'Jane',
        email: 'jane@acme.test',
        role: InvitationRole.manager,
      );
      const b = InvitationMock(
        organization: 'Acme',
        inviter: 'Jane',
        email: 'jane@acme.test',
        role: InvitationRole.manager,
      );
      expect(a, equals(b));
    });

    test('differs when role differs', () {
      const worker = InvitationMock(
        organization: 'Acme',
        inviter: 'Jane',
        email: 'jane@acme.test',
        role: InvitationRole.worker,
      );
      const manager = InvitationMock(
        organization: 'Acme',
        inviter: 'Jane',
        email: 'jane@acme.test',
        role: InvitationRole.manager,
      );
      expect(worker, isNot(equals(manager)));
    });
  });
}
