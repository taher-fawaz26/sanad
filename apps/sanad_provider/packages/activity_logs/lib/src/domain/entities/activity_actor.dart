import 'package:equatable/equatable.dart';

/// `actor.type` — drives rendering, not [ActivityActor.name] shape.
enum ActivityActorType {
  owner,
  manager,
  worker,
  admin,
  system,
  unknown
  ;

  static ActivityActorType fromApiValue(String? value) =>
      ActivityActorType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => unknown,
      );
}

/// Who performed an activity-log event.
///
/// Render [name] as-is for owner/manager/worker. For [ActivityActorType.admin]
/// the backend always intends "Sanad Support" — never look up the admin user.
/// For [ActivityActorType.system], use the platform identity. Never infer
/// [type] from [name].
class ActivityActor extends Equatable {
  const ActivityActor({required this.name, required this.type, this.id});

  final String? id;
  final String name;
  final ActivityActorType type;

  @override
  List<Object?> get props => [id, name, type];
}
