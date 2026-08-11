import 'package:flutter_test/flutter_test.dart';
import 'package:workers/src/data/models/update_worker_status_dto.dart';
import 'package:workers/src/domain/entities/worker_status.dart';

void main() {
  group('UpdateWorkerStatusDto.toJson — contract', () {
    // Regression: the status body must be a valid backend enum
    // (`active`|`inactive`), never the old `suspended` value.
    test('active serializes as {status: active}', () {
      final json = UpdateWorkerStatusDto.fromStatus(
        WorkerStatus.active,
      ).toJson();
      expect(json, {'status': 'active'});
    });

    test('inactive serializes as {status: inactive}', () {
      final json = UpdateWorkerStatusDto.fromStatus(
        WorkerStatus.inactive,
      ).toJson();
      expect(json, {'status': 'inactive'});
    });

    test('body contains only the status key', () {
      final json = UpdateWorkerStatusDto.fromStatus(
        WorkerStatus.active,
      ).toJson();
      expect(json.keys, ['status']);
    });
  });
}
