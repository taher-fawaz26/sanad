import 'package:equatable/equatable.dart';
import 'package:permissions/src/domain/enums/permission_status.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';

/// Rich result returned by every check and request operation.
///
/// All status helpers are computed properties so call-sites never need to
/// import or switch over [PermissionStatus] directly.
class PermissionResult extends Equatable {
  const PermissionResult({
    required this.permission,
    required this.status,
    this.message,
  });

  final PermissionType permission;
  final PermissionStatus status;

  /// Optional human-readable context (rationale, error detail, etc.).
  final String? message;

  /// True when the permission is usable — granted, limited, or provisional.
  bool get isGranted =>
      status == PermissionStatus.granted ||
      status == PermissionStatus.limited ||
      status == PermissionStatus.provisional;

  bool get isDenied => status == PermissionStatus.denied;

  bool get isLimited => status == PermissionStatus.limited;

  bool get isPermanentlyDenied => status == PermissionStatus.permanentlyDenied;

  bool get isRestricted => status == PermissionStatus.restricted;

  /// True when navigating to app settings is the only recovery path.
  bool get canOpenSettings => isPermanentlyDenied || isRestricted;

  PermissionResult copyWith({
    PermissionType? permission,
    PermissionStatus? status,
    String? message,
  }) {
    return PermissionResult(
      permission: permission ?? this.permission,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [permission, status, message];

  @override
  String toString() =>
      'PermissionResult(permission: $permission, status: $status)';
}
