import 'package:activity_logs/src/domain/entities/activity_action.dart';
import 'package:activity_logs/src/domain/entities/activity_actor.dart';
import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/domain/entities/activity_metadata.dart';
import 'package:activity_logs/src/domain/entities/activity_subject.dart';
import 'package:core/core.dart';

class ActivityLogDto extends ActivityLogEntry
    implements EntityConverter<ActivityLogEntry> {
  const ActivityLogDto({
    required super.action,
    required super.name,
    required super.timestamp,
    required super.actor,
    super.subject,
    super.metadata,
  });

  factory ActivityLogDto.fromJson(Map<String, dynamic> json) {
    final actorJson = json['actor'] as Map<String, dynamic>?;
    final subjectJson = json['subject'] as Map<String, dynamic>?;
    final metadataJson = json['metadata'] as Map<String, dynamic>?;

    return ActivityLogDto(
      action: ActivityAction.fromApiValue(json['action'] as String?),
      name: json['name'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      actor: ActivityActor(
        id: actorJson?['id'] as String?,
        name: actorJson?['name'] as String? ?? '',
        type: ActivityActorType.fromApiValue(actorJson?['type'] as String?),
      ),
      subject: subjectJson == null
          ? null
          : ActivitySubject(
              type: ActivitySubjectType.fromApiValue(
                subjectJson['type'] as String?,
              ),
              id: subjectJson['id'] as String? ?? '',
              name: subjectJson['name'] as String?,
            ),
      metadata: metadataJson == null ? null : ActivityMetadata(metadataJson),
    );
  }

  @override
  ActivityLogEntry toEntity() => ActivityLogEntry(
    action: action,
    name: name,
    timestamp: timestamp,
    actor: actor,
    subject: subject,
    metadata: metadata,
  );
}
