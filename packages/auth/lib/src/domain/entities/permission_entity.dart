import 'package:equatable/equatable.dart';

/// Permission entry returned on authenticated session responses.
class PermissionEntity extends Equatable {
  const PermissionEntity({
    required this.name,
    this.resource,
    this.action,
  });

  final String name;
  final String? resource;
  final String? action;

  @override
  List<Object?> get props => [name, resource, action];
}
