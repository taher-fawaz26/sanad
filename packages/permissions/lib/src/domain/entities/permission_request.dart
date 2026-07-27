import 'package:equatable/equatable.dart';
import 'package:permissions/src/config/permission_config.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';

/// Encapsulates a single permission request together with its optional
/// per-request policy override and custom dialog texts.
class PermissionRequest extends Equatable {
  const PermissionRequest({
    required this.type,
    this.policy,
    this.rationaleTitle,
    this.rationaleMessage,
  });

  final PermissionType type;

  /// Per-request policy override; falls back to
  /// [PermissionConfig.defaultPolicy].
  final PermissionPolicy? policy;

  /// Custom title for the rationale dialog shown before requesting.
  final String? rationaleTitle;

  /// Custom message for the rationale dialog shown before requesting.
  final String? rationaleMessage;

  @override
  List<Object?> get props => [type, policy, rationaleTitle, rationaleMessage];
}
