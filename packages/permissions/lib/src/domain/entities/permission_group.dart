import 'package:equatable/equatable.dart';
import 'package:permissions/src/domain/entities/permission_request.dart';

/// A named collection of [PermissionRequest]s that belong to the same
/// logical feature and should be requested as a unit.
class PermissionGroup extends Equatable {
  const PermissionGroup({
    required this.name,
    required this.requests,
  });

  final String name;
  final List<PermissionRequest> requests;

  @override
  List<Object?> get props => [name, requests];
}
