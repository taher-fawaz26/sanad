import 'package:equatable/equatable.dart';

/// Configures the automatic UX flow for a permission request.
///
/// Supply a per-call override to [PermissionService.request] /
/// [Permissions.ensure*] to override the app-wide default.
class PermissionPolicy extends Equatable {
  const PermissionPolicy({
    this.showRationale = true,
    this.showSettingsDialog = true,
    this.autoOpenSettings = false,
  });

  /// Show a rationale bottom-sheet before requesting a [denied] permission.
  final bool showRationale;

  /// Show a settings bottom-sheet when the permission is [permanentlyDenied].
  final bool showSettingsDialog;

  /// Automatically open app settings without asking the user first.
  /// Takes precedence over [showSettingsDialog] when both are true.
  final bool autoOpenSettings;

  @override
  List<Object?> get props => [
    showRationale,
    showSettingsDialog,
    autoOpenSettings,
  ];
}

/// App-wide configuration for the permissions package.
///
/// Pass a custom instance to [PermissionsModule] at bootstrap to change the
/// default UX behaviour across all [Permissions.ensure*] calls.
class PermissionConfig extends Equatable {
  const PermissionConfig({
    this.defaultPolicy = const PermissionPolicy(),
  });

  /// Policy applied to every request that does not supply its own override.
  final PermissionPolicy defaultPolicy;

  @override
  List<Object?> get props => [defaultPolicy];
}
