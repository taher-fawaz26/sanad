import 'package:authorization/src/domain/permission_set.dart';
import 'package:equatable/equatable.dart';

/// Composition of one or more permission actions into a single pass/fail
/// decision. Exactly three primitives — `single`, `any`, `all` — because
/// those are the three the application actually needs today. No expression
/// tree, no negation, no nesting until a real requirement demands one.
sealed class PermissionRequirement extends Equatable {
  const PermissionRequirement();

  /// Satisfied iff the evaluated [PermissionSet] grants [action].
  const factory PermissionRequirement.single(String action) =
      SinglePermissionRequirement;

  /// Satisfied iff the evaluated [PermissionSet] grants any action in
  /// [actions].
  const factory PermissionRequirement.any(Set<String> actions) =
      AnyPermissionRequirement;

  /// Satisfied iff the evaluated [PermissionSet] grants every action in
  /// [actions].
  const factory PermissionRequirement.all(Set<String> actions) =
      AllPermissionRequirement;

  bool isSatisfiedBy(PermissionSet permissions);
}

final class SinglePermissionRequirement extends PermissionRequirement {
  const SinglePermissionRequirement(this.action);

  final String action;

  @override
  bool isSatisfiedBy(PermissionSet permissions) => permissions.can(action);

  @override
  List<Object?> get props => [action];
}

final class AnyPermissionRequirement extends PermissionRequirement {
  const AnyPermissionRequirement(this.actions);

  final Set<String> actions;

  @override
  bool isSatisfiedBy(PermissionSet permissions) => permissions.canAny(actions);

  @override
  List<Object?> get props => [actions];
}

final class AllPermissionRequirement extends PermissionRequirement {
  const AllPermissionRequirement(this.actions);

  final Set<String> actions;

  @override
  bool isSatisfiedBy(PermissionSet permissions) => permissions.canAll(actions);

  @override
  List<Object?> get props => [actions];
}
