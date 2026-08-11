import 'package:flutter_test/flutter_test.dart';
import 'package:workers/src/data/models/worker_dto.dart';
import 'package:workers/src/domain/entities/worker_status.dart';

void main() {
  // Shaped after the backend `WorkerProfileResponseDto` (OpenAPI 3.0.0).
  Map<String, dynamic> workerJson() => {
    'id': 'wrk_1',
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'phone': '+971501234567',
    'jobTitle': 'Software Engineer',
    'type': 'manager',
    'status': 'inactive',
    'profilePic': {
      'id': 'media_1',
      'url': 'https://cdn.example.com/john.jpg',
    },
    'assignedBranches': [
      {'id': 'br_1', 'branchName': 'Downtown', 'role': 'manager'},
      {'id': 'br_2', 'branchName': 'Marina', 'role': 'worker'},
    ],
    'createdAt': '2026-01-01T10:00:00.000Z',
  };

  group('WorkerDto.fromJson — contract', () {
    test('maps name→fullName, type→role, jobTitle, and computes initials', () {
      final dto = WorkerDto.fromJson(workerJson());
      expect(dto.id, 'wrk_1');
      expect(dto.fullName, 'John Doe');
      expect(dto.role, 'manager');
      expect(dto.email, 'john.doe@example.com');
      expect(dto.phone, '+971501234567');
      expect(dto.jobTitle, 'Software Engineer');
      expect(dto.initials, 'JD');
    });

    test('parses profilePic.url into profilePicUrl', () {
      final dto = WorkerDto.fromJson(workerJson());
      expect(dto.profilePicUrl, 'https://cdn.example.com/john.jpg');
    });

    test('null profilePic yields null profilePicUrl', () {
      final json = workerJson()..['profilePic'] = null;
      expect(WorkerDto.fromJson(json).profilePicUrl, isNull);
    });

    test('parses assignedBranches array into structured branches', () {
      final dto = WorkerDto.fromJson(workerJson());
      expect(dto.assignedBranches, hasLength(2));
      expect(dto.assignedBranches.first.id, 'br_1');
      expect(dto.assignedBranches.first.branchName, 'Downtown');
      expect(dto.assignedBranches.first.role, 'manager');
      expect(dto.assignedBranches[1].branchName, 'Marina');
    });

    test('missing assignedBranches yields empty list', () {
      final json = workerJson()..remove('assignedBranches');
      expect(WorkerDto.fromJson(json).assignedBranches, isEmpty);
    });

    // Regression: the old DTO read a non-existent `branches` string. Ensure a
    // legacy `branches` field is ignored and never populates the list.
    test('ignores a legacy top-level "branches" string', () {
      final json = workerJson()
        ..remove('assignedBranches')
        ..['branches'] = 'Downtown, Marina';
      expect(WorkerDto.fromJson(json).assignedBranches, isEmpty);
    });

    group('status enum (active|inactive only)', () {
      test('active → WorkerStatus.active', () {
        final json = workerJson()..['status'] = 'active';
        expect(WorkerDto.fromJson(json).status, WorkerStatus.active);
      });

      test('inactive → WorkerStatus.inactive', () {
        expect(WorkerDto.fromJson(workerJson()).status, WorkerStatus.inactive);
      });

      // Regression: unknown/legacy values must NOT resolve to a removed
      // `pending`/`suspended` state.
      test('unknown status defaults to inactive', () {
        final json = workerJson()..['status'] = 'suspended';
        expect(WorkerDto.fromJson(json).status, WorkerStatus.inactive);
      });

      test('null status defaults to inactive', () {
        final json = workerJson()..['status'] = null;
        expect(WorkerDto.fromJson(json).status, WorkerStatus.inactive);
      });
    });
  });
}
