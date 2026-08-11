import 'package:flutter_test/flutter_test.dart';
import 'package:workers/src/data/models/update_worker_dto.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/domain/usecases/update_worker_usecase.dart';

void main() {
  const params = UpdateWorkerParams(
    id: 'wrk_1',
    fullName: 'John Doe',
    jobTitle: 'Software Engineer',
    type: WorkerType.worker,
    phone: '+971501234567',
  );

  group('UpdateWorkerDto.toJson — contract', () {
    test('serializes name, phone, jobTitle, type', () {
      final json = UpdateWorkerDto.fromParams(params).toJson();
      expect(json, {
        'name': 'John Doe',
        'phone': '+971501234567',
        'jobTitle': 'Software Engineer',
        'type': 'worker',
      });
    });

    // Regression: email is not server-editable and must never be sent.
    test('never emits email', () {
      final json = UpdateWorkerDto.fromParams(params).toJson();
      expect(json.containsKey('email'), isFalse);
    });

    // Regression: branch is not part of the update contract; the id is a path
    // parameter, not a body field; status has its own endpoint.
    test('never emits branch, id, or status', () {
      final json = UpdateWorkerDto.fromParams(params).toJson();
      expect(json.containsKey('branchId'), isFalse);
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('status'), isFalse);
    });

    test('null phone is omitted', () {
      final json = UpdateWorkerDto.fromParams(
        const UpdateWorkerParams(
          id: 'wrk_1',
          fullName: 'John Doe',
          jobTitle: 'Software Engineer',
          type: WorkerType.worker,
        ),
      ).toJson();
      expect(json.containsKey('phone'), isFalse);
    });

    test('empty jobTitle is omitted', () {
      final json = UpdateWorkerDto.fromParams(
        const UpdateWorkerParams(
          id: 'wrk_1',
          fullName: 'John Doe',
          jobTitle: '',
          type: WorkerType.manager,
          phone: '+971501234567',
        ),
      ).toJson();
      expect(json.containsKey('jobTitle'), isFalse);
      expect(json['type'], 'manager');
    });
  });
}
