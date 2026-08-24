import 'package:equatable/equatable.dart';

/// `subject.type` — the record kind an activity-log event was about.
enum ActivitySubjectType {
  branch,
  worker,
  invitation,
  providerService,
  serviceRequest,
  role,
  account,
  unknown;

  static ActivitySubjectType fromApiValue(String? value) =>
      ActivitySubjectType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => unknown,
      );
}

/// The record an activity-log event was about. Present on most rows but
/// never guaranteed — always null-check before use.
///
/// [name] is a historical snapshot taken at event time. Never reconcile it
/// against the subject's current (possibly renamed or deleted) live state.
class ActivitySubject extends Equatable {
  const ActivitySubject({required this.type, required this.id, this.name});

  final ActivitySubjectType type;
  final String id;
  final String? name;

  @override
  List<Object?> get props => [type, id, name];
}
