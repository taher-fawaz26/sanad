import 'package:equatable/equatable.dart';

/// A single permission from the live provider permission catalog
/// (`GET /api/v1/provider/permissions`).
class PermissionEntity extends Equatable {
  const PermissionEntity({
    required this.id,
    required this.action,
    required this.displayName,
    required this.resource,
    this.description,
    this.isAdmin = false,
  });

  final String id;

  /// e.g. `provider:branch:create`.
  final String action;
  final String displayName;
  final String? description;

  /// e.g. `branch`.
  final String resource;

  /// Whether this is an admin-scoped permission. The provider permission
  /// catalog only returns worker-assignable permissions (`isAdmin: false`),
  /// but the field is carried through faithfully from the backend contract.
  final bool isAdmin;

  @override
  List<Object?> get props => [
    id,
    action,
    displayName,
    description,
    resource,
    isAdmin,
  ];
}
