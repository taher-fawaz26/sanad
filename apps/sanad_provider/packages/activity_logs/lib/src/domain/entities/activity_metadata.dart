import 'package:equatable/equatable.dart';

/// Flexible wrapper over the action-specific `metadata` object.
///
/// Its shape varies across the 53 activity-log actions (e.g.
/// `branchStatusChanged` carries `{previousStatus, status}`, while
/// `providerRoleCreated` carries `{roleName}`), so this stays a safe,
/// null-tolerant accessor rather than a rigid per-action DTO.
class ActivityMetadata extends Equatable {
  const ActivityMetadata(this.raw);

  static const empty = ActivityMetadata(<String, dynamic>{});

  final Map<String, dynamic> raw;

  T? value<T>(String key) => raw[key] as T?;

  @override
  List<Object?> get props => [raw];
}
