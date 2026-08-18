import 'package:flutter_test/flutter_test.dart';
import 'package:workers/src/data/models/create_invitation_dto.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';

void main() {
  // Values taken from the backend `CreateInvitationDto` OpenAPI examples.
  const params = InviteWorkerParams(
    fullName: 'John Doe',
    jobTitle: 'Software Engineer',
    type: WorkerType.worker,
    email: 'john.doe@example.com',
    phone: '+971501234567',
    roleIds: ['f490f1ee-6c54-4b01-90e6-d701748f0851'],
  );

  group('CreateInvitationDto.toJson — contract', () {
    test('serializes exactly the backend CreateInvitationDto shape', () {
      final json = CreateInvitationDto.fromParams(params).toJson();
      expect(json, {
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'phone': '+971501234567',
        'jobTitle': 'Software Engineer',
        'type': 'worker',
        'roleIds': ['f490f1ee-6c54-4b01-90e6-d701748f0851'],
      });
    });

    test('type manager serializes as "manager"', () {
      final json = CreateInvitationDto.fromParams(
        const InviteWorkerParams(
          fullName: 'Jane Roe',
          jobTitle: 'Lead',
          type: WorkerType.manager,
          email: 'jane@example.com',
          phone: '+971500000000',
          roleIds: ['branch-manager-role-id'],
        ),
      ).toJson();
      expect(json['type'], 'manager');
    });

    test('empty jobTitle is omitted (optional field)', () {
      final json = CreateInvitationDto.fromParams(
        const InviteWorkerParams(
          fullName: 'John Doe',
          jobTitle: '',
          type: WorkerType.worker,
          email: 'john.doe@example.com',
          phone: '+971501234567',
          roleIds: ['worker-basic-role-id'],
        ),
      ).toJson();
      expect(json.containsKey('jobTitle'), isFalse);
    });

    test('roleIds is always emitted, even when empty', () {
      final json = CreateInvitationDto.fromParams(
        const InviteWorkerParams(
          fullName: 'John Doe',
          jobTitle: '',
          type: WorkerType.worker,
          email: 'john.doe@example.com',
          phone: '+971501234567',
          roleIds: [],
        ),
      ).toJson();
      expect(json['roleIds'], <String>[]);
    });

    // Regression: branch is not part of the invitation contract.
    test('never emits a branch field', () {
      final json = CreateInvitationDto.fromParams(params).toJson();
      expect(json.containsKey('branchId'), isFalse);
      expect(json.containsKey('branch'), isFalse);
    });
  });
}
