import 'package:equatable/equatable.dart';

/// A single permission from the live provider permission catalog
/// (`GET /api/v1/provider/permissions`).
class PermissionEntity extends Equatable {
  const PermissionEntity({
    required this.id,
    required this.action,
    required this.displayName,
    required this.resource,
    this.displayNameAr,
    this.description,
  });

  final String id;

  /// e.g. `branch:create`.
  final String action;
  final String displayName;
  final String? displayNameAr;
  final String? description;

  /// e.g. `branch`.
  final String resource;

  @override
  List<Object?> get props => [
    id,
    action,
    displayName,
    displayNameAr,
    description,
    resource,
  ];
}
