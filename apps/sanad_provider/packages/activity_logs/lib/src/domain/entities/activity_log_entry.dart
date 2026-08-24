import 'package:activity_logs/src/domain/entities/activity_action.dart';
import 'package:activity_logs/src/domain/entities/activity_actor.dart';
import 'package:activity_logs/src/domain/entities/activity_metadata.dart';
import 'package:activity_logs/src/domain/entities/activity_subject.dart';
import 'package:equatable/equatable.dart';

/// One row of `GET /activity-logs`.
///
/// Switch on [action] — the stable discriminator — never on [name], which is
/// server-localized display text. [subject] and [metadata] are both
/// optional on every row; null-check before use.
class ActivityLogEntry extends Equatable {
  const ActivityLogEntry({
    required this.action,
    required this.name,
    required this.timestamp,
    required this.actor,
    this.subject,
    this.metadata,
  });

  final ActivityAction action;
  final String name;
  final DateTime timestamp;
  final ActivityActor actor;
  final ActivitySubject? subject;
  final ActivityMetadata? metadata;

  @override
  List<Object?> get props => [
    action,
    name,
    timestamp,
    actor,
    subject,
    metadata,
  ];
}
