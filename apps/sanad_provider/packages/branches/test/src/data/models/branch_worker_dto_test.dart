import 'package:branches/src/data/models/branch_worker_dto.dart';
import 'package:branches/src/domain/entities/branch_worker_entity.dart';
import 'package:branches/src/domain/entities/branch_worker_type.dart';
import 'package:branches/src/domain/entities/worker_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const workerJson = <String, dynamic>{
    'id': 'w-1',
    'name': 'Ali Hassan',
    'email': 'ali@example.com',
    'phone': '+971500000001',
    'type': 'worker',
    'status': 'active',
  };

  const managerJson = <String, dynamic>{
    'id': 'm-1',
    'name': 'Sara Mohamed',
    'email': 'sara@example.com',
    'phone': '+971500000002',
    'type': 'manager',
    'status': 'inactive',
  };

  group('BranchWorkerDto.fromJson', () {
    test('parses a worker entry correctly', () {
      final dto = BranchWorkerDto.fromJson(workerJson);
      expect(dto.id, 'w-1');
      expect(dto.name, 'Ali Hassan');
      expect(dto.type, BranchWorkerType.worker);
      expect(dto.status, WorkerStatus.active);
    });

    test('parses a manager entry correctly', () {
      final dto = BranchWorkerDto.fromJson(managerJson);
      expect(dto.id, 'm-1');
      expect(dto.name, 'Sara Mohamed');
      expect(dto.type, BranchWorkerType.manager);
      expect(dto.status, WorkerStatus.inactive);
    });

    test('unknown type defaults to worker', () {
      final dto = BranchWorkerDto.fromJson({
        ...workerJson,
        'type': 'unknown_value',
      });
      expect(dto.type, BranchWorkerType.worker);
    });

    test('unknown status defaults to active', () {
      final dto = BranchWorkerDto.fromJson({
        ...workerJson,
        'status': 'unknown_value',
      });
      expect(dto.status, WorkerStatus.active);
    });

    test('null type defaults to worker', () {
      final dto = BranchWorkerDto.fromJson({...workerJson, 'type': null});
      expect(dto.type, BranchWorkerType.worker);
    });

    test('null status defaults to active', () {
      final dto = BranchWorkerDto.fromJson({...workerJson, 'status': null});
      expect(dto.status, WorkerStatus.active);
    });
  });

  group('BranchWorkerDto.toDomain — initials', () {
    test('computes two-word initials', () {
      final entity = BranchWorkerDto.fromJson(workerJson).toDomain();
      expect(entity.initials, 'AH');
    });

    test('computes single-word initial', () {
      final entity = BranchWorkerDto.fromJson({
        ...workerJson,
        'name': 'Taher',
      }).toDomain();
      expect(entity.initials, 'T');
    });

    test('takes only the first two words', () {
      final entity = BranchWorkerDto.fromJson({
        ...workerJson,
        'name': 'Ali Hassan Khalid',
      }).toDomain();
      expect(entity.initials, 'AH');
    });

    test('uppercases initials', () {
      final entity = BranchWorkerDto.fromJson({
        ...workerJson,
        'name': 'ali hassan',
      }).toDomain();
      expect(entity.initials, 'AH');
    });

    test('handles extra whitespace', () {
      final entity = BranchWorkerDto.fromJson({
        ...workerJson,
        'name': '  Ali   Hassan  ',
      }).toDomain();
      expect(entity.initials, 'AH');
    });

    test('empty name yields empty initials', () {
      final entity = BranchWorkerDto.fromJson({
        ...workerJson,
        'name': '',
      }).toDomain();
      expect(entity.initials, '');
    });
  });

  group('BranchWorkerDto.toDomain — entity mapping', () {
    test('maps all fields to BranchWorkerEntity', () {
      final entity = BranchWorkerDto.fromJson(workerJson).toDomain();
      expect(entity, isA<BranchWorkerEntity>());
      expect(entity.id, 'w-1');
      expect(entity.fullName, 'Ali Hassan');
      expect(entity.type, BranchWorkerType.worker);
      expect(entity.status, WorkerStatus.active);
    });

    test('isManager is false for worker type', () {
      final entity = BranchWorkerDto.fromJson(workerJson).toDomain();
      expect(entity.isManager, isFalse);
    });

    test('isManager is true for manager type', () {
      final entity = BranchWorkerDto.fromJson(managerJson).toDomain();
      expect(entity.isManager, isTrue);
    });

    test('isActive is true for active status', () {
      final entity = BranchWorkerDto.fromJson(workerJson).toDomain();
      expect(entity.isActive, isTrue);
    });

    test('isActive is false for inactive status', () {
      final entity = BranchWorkerDto.fromJson(managerJson).toDomain();
      expect(entity.isActive, isFalse);
    });
  });

  group('BranchDto workers integration', () {
    test('BranchWorkerType round-trips through toApiString/fromApiString', () {
      for (final type in BranchWorkerType.values) {
        expect(BranchWorkerType.fromApiString(type.toApiString()), type);
      }
    });

    test('WorkerStatus round-trips through toApiString/fromApiString', () {
      for (final status in WorkerStatus.values) {
        expect(WorkerStatus.fromApiString(status.toApiString()), status);
      }
    });
  });
}
