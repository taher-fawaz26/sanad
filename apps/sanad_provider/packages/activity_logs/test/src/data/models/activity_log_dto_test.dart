import 'package:activity_logs/src/data/models/activity_log_dto.dart';
import 'package:activity_logs/src/domain/entities/activity_action.dart';
import 'package:activity_logs/src/domain/entities/activity_actor.dart';
import 'package:activity_logs/src/domain/entities/activity_subject.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> entryJson() => {
    'action': 'branchStatusChanged',
    'name': 'Changed a branch status',
    'timestamp': '2026-08-20T09:14:02.113Z',
    'actor': {
      'id': 'f490f1ee-6c54-4b01-90e6-d701748f0851',
      'name': 'Layla Al Mansoori',
      'type': 'owner',
    },
    'subject': {
      'type': 'branch',
      'id': '0f2b8a1c-8f3e-4a2d-9c11-6b0d2e7a4f55',
      'name': 'Marina Branch',
    },
    'metadata': {'previousStatus': 'ACTIVE', 'status': 'MAINTENANCE'},
  };

  group('ActivityLogDto.fromJson — contract', () {
    test('maps a full entry', () {
      final dto = ActivityLogDto.fromJson(entryJson());

      expect(dto.action, ActivityAction.branchStatusChanged);
      expect(dto.name, 'Changed a branch status');
      expect(dto.timestamp, DateTime.parse('2026-08-20T09:14:02.113Z'));
      expect(dto.actor.id, 'f490f1ee-6c54-4b01-90e6-d701748f0851');
      expect(dto.actor.name, 'Layla Al Mansoori');
      expect(dto.actor.type, ActivityActorType.owner);
      expect(dto.subject?.type, ActivitySubjectType.branch);
      expect(dto.subject?.name, 'Marina Branch');
      expect(dto.metadata?.value<String>('previousStatus'), 'ACTIVE');
      expect(dto.metadata?.value<String>('status'), 'MAINTENANCE');
    });

    test('null subject is preserved as null, not a default value', () {
      final json = entryJson()..remove('subject');
      expect(ActivityLogDto.fromJson(json).subject, isNull);
    });

    test('null metadata is preserved as null', () {
      final json = entryJson()..remove('metadata');
      expect(ActivityLogDto.fromJson(json).metadata, isNull);
    });

    test('unknown action falls back to ActivityAction.unknown', () {
      final json = entryJson()..['action'] = 'someFutureAction';
      expect(ActivityLogDto.fromJson(json).action, ActivityAction.unknown);
    });

    test('unknown subjectType falls back to ActivitySubjectType.unknown', () {
      final json = entryJson();
      (json['subject'] as Map<String, dynamic>)['type'] = 'somethingNew';
      expect(
        ActivityLogDto.fromJson(json).subject?.type,
        ActivitySubjectType.unknown,
      );
    });

    for (final type in ['owner', 'manager', 'worker', 'admin', 'system']) {
      test('actor.type "$type" round-trips', () {
        final json = entryJson();
        (json['actor'] as Map<String, dynamic>)['type'] = type;
        expect(
          ActivityLogDto.fromJson(json).actor.type.name,
          type,
        );
      });
    }

    test('unknown actor.type falls back to ActivityActorType.unknown', () {
      final json = entryJson();
      (json['actor'] as Map<String, dynamic>)['type'] = 'bot';
      expect(
        ActivityLogDto.fromJson(json).actor.type,
        ActivityActorType.unknown,
      );
    });

    test('subject without a name is still parsed (name null)', () {
      final json = entryJson();
      (json['subject'] as Map<String, dynamic>).remove('name');
      expect(ActivityLogDto.fromJson(json).subject?.name, isNull);
    });

    test('malformed timestamp falls back gracefully instead of throwing', () {
      final json = entryJson()..['timestamp'] = 'not-a-date';
      expect(() => ActivityLogDto.fromJson(json), returnsNormally);
    });

    test('toEntity() copies every field', () {
      final dto = ActivityLogDto.fromJson(entryJson());
      final entity = dto.toEntity();

      expect(entity.action, dto.action);
      expect(entity.name, dto.name);
      expect(entity.timestamp, dto.timestamp);
      expect(entity.actor, dto.actor);
      expect(entity.subject, dto.subject);
      expect(entity.metadata, dto.metadata);
    });
  });
}
