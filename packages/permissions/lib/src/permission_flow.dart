import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:permissions/src/config/permission_config.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/theme/permission_explanation.dart';

/// A declarative, callback-driven permission flow.
///
/// Higher-level alternative to manually inspecting a `PermissionResult`.
/// Pass one to [Permissions.execute]; the façade runs the full ensure flow
/// (check → rationale → request → settings redirect) then dispatches exactly
/// one status callback.
///
/// ```dart
/// await Permissions.execute(
///   PermissionFlow(
///     permission: PermissionType.camera,
///     context: context,
///     onGranted: () async => _openCamera(),
///     onPermanentDenied: () => _showManualHint(),
///   ),
/// );
/// ```
///
/// All callbacks are optional — omit the ones a feature does not care about.
class PermissionFlow {
  const PermissionFlow({
    required this.permission,
    this.context,
    this.policy,
    this.explanation,
    this.onGranted,
    this.onDenied,
    this.onPermanentDenied,
    this.onRestricted,
    this.onLimited,
  });

  /// The permission to ensure.
  final PermissionType permission;

  /// Build context used to display rationale / settings dialogs. When `null`,
  /// no dialogs are shown (headless flow).
  final BuildContext? context;

  /// Per-flow policy override; falls back to [PermissionConfig.defaultPolicy].
  final PermissionPolicy? policy;

  /// Per-flow explanation override for the rationale dialog.
  final PermissionExplanation? explanation;

  /// Invoked when the permission ends up granted (or provisional).
  final FutureOr<void> Function()? onGranted;

  /// Invoked when the permission is denied but may be requested again.
  final FutureOr<void> Function()? onDenied;

  /// Invoked when the permission is permanently denied.
  final FutureOr<void> Function()? onPermanentDenied;

  /// Invoked when the permission is restricted by OS policy.
  final FutureOr<void> Function()? onRestricted;

  /// Invoked when the permission is granted with limited scope (iOS).
  /// Falls back to [onGranted] when not provided.
  final FutureOr<void> Function()? onLimited;
}
