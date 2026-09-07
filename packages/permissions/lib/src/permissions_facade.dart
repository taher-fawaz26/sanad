import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:permissions/src/config/permission_config.dart';
import 'package:permissions/src/domain/entities/permission_result.dart';
import 'package:permissions/src/domain/enums/permission_status.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/domain/services/permission_service.dart';
import 'package:permissions/src/permission_flow.dart';
import 'package:permissions/src/presentation/dialogs/permission_rationale_dialog.dart';
import 'package:permissions/src/presentation/dialogs/permission_settings_dialog.dart';
import 'package:permissions/src/theme/permission_explanation.dart';
import 'package:permissions/src/theme/permission_theme.dart';

/// Static façade over [PermissionService].
///
/// This is the public API that every feature in the monorepo uses.
/// Features never instantiate [PermissionService] directly — they call
/// methods on this class after [PermissionsModule] has registered the DI
/// bindings at bootstrap.
///
/// ```dart
/// // Simple check
/// final result = await Permissions.checkCamera();
///
/// // Ensure with full UX flow (rationale + settings redirect)
/// final result = await Permissions.ensureCamera(context: context);
/// if (!result.isGranted) return;
/// ```
abstract final class Permissions {
  Permissions._();

  static PermissionService get _service => sl<PermissionService>();
  static PermissionConfig get _config => sl<PermissionConfig>();
  static PermissionTheme get _theme {
    if (sl.isRegistered<PermissionTheme>()) return sl<PermissionTheme>();
    return const PermissionTheme();
  }

  // ---------------------------------------------------------------------------
  // Core API
  // ---------------------------------------------------------------------------

  /// Checks the current status of [type] without prompting the user.
  static Future<PermissionResult> check(PermissionType type) =>
      _service.check(type);

  /// Checks multiple permission types without prompting the user.
  static Future<Map<PermissionType, PermissionResult>> checkMany(
    List<PermissionType> types,
  ) => _service.checkMany(types);

  /// Requests a single [type] from the OS.
  static Future<PermissionResult> request(
    PermissionType type, {
    PermissionPolicy? policy,
  }) => _service.request(type, policy: policy);

  /// Requests multiple permissions in a single OS-level batch.
  static Future<Map<PermissionType, PermissionResult>> requestMany(
    List<PermissionType> types, {
    PermissionPolicy? policy,
  }) => _service.requestMany(types, policy: policy);

  /// Opens the host app's entry in the device settings.
  static Future<bool> openSettings() => _service.openSettings();

  // ---------------------------------------------------------------------------
  // Convenience: request shortcuts
  // ---------------------------------------------------------------------------

  static Future<PermissionResult> requestCamera({PermissionPolicy? policy}) =>
      request(PermissionType.camera, policy: policy);

  static Future<PermissionResult> requestGallery({PermissionPolicy? policy}) =>
      request(PermissionType.gallery, policy: policy);

  static Future<PermissionResult> requestPhotos({PermissionPolicy? policy}) =>
      request(PermissionType.photos, policy: policy);

  static Future<PermissionResult> requestLocation({PermissionPolicy? policy}) =>
      request(PermissionType.locationWhenInUse, policy: policy);

  static Future<PermissionResult> requestLocationAlways({
    PermissionPolicy? policy,
  }) => request(PermissionType.locationAlways, policy: policy);

  static Future<PermissionResult> requestNotifications({
    PermissionPolicy? policy,
  }) => request(PermissionType.notifications, policy: policy);

  static Future<PermissionResult> requestMicrophone({
    PermissionPolicy? policy,
  }) => request(PermissionType.microphone, policy: policy);

  static Future<PermissionResult> requestContacts({PermissionPolicy? policy}) =>
      request(PermissionType.contacts, policy: policy);

  static Future<PermissionResult> requestBluetooth({
    PermissionPolicy? policy,
  }) => request(PermissionType.bluetooth, policy: policy);

  // ---------------------------------------------------------------------------
  // Convenience: check shortcuts
  // ---------------------------------------------------------------------------

  static Future<PermissionResult> checkCamera() => check(PermissionType.camera);

  static Future<PermissionResult> checkGallery() =>
      check(PermissionType.gallery);

  static Future<PermissionResult> checkPhotos() => check(PermissionType.photos);

  static Future<PermissionResult> checkLocation() =>
      check(PermissionType.locationWhenInUse);

  static Future<PermissionResult> checkNotifications() =>
      check(PermissionType.notifications);

  static Future<PermissionResult> checkMicrophone() =>
      check(PermissionType.microphone);

  // ---------------------------------------------------------------------------
  // Ensure API — full UX flow with optional dialog support
  // ---------------------------------------------------------------------------

  /// Ensures the camera permission is granted, running the full UX flow.
  ///
  /// Behaviour (controlled by [policy] / [PermissionConfig.defaultPolicy]):
  ///  1. Already granted → return immediately.
  ///  2. Denied → optionally show rationale bottom-sheet → request.
  ///  3. Permanently denied → optionally show settings redirect sheet.
  ///
  /// ```dart
  /// final result = await Permissions.ensureCamera(context: context);
  /// if (!result.isGranted) return;
  /// ```
  static Future<PermissionResult> ensureCamera({
    BuildContext? context,
    PermissionPolicy? policy,
  }) => _ensure(PermissionType.camera, context: context, policy: policy);

  static Future<PermissionResult> ensureGallery({
    BuildContext? context,
    PermissionPolicy? policy,
  }) => _ensure(PermissionType.gallery, context: context, policy: policy);

  static Future<PermissionResult> ensurePhotos({
    BuildContext? context,
    PermissionPolicy? policy,
  }) => _ensure(PermissionType.photos, context: context, policy: policy);

  static Future<PermissionResult> ensureLocation({
    BuildContext? context,
    PermissionPolicy? policy,
  }) => _ensure(
    PermissionType.locationWhenInUse,
    context: context,
    policy: policy,
  );

  static Future<PermissionResult> ensureLocationAlways({
    BuildContext? context,
    PermissionPolicy? policy,
  }) => _ensure(
    PermissionType.locationAlways,
    context: context,
    policy: policy,
  );

  static Future<PermissionResult> ensureNotifications({
    BuildContext? context,
    PermissionPolicy? policy,
  }) => _ensure(PermissionType.notifications, context: context, policy: policy);

  static Future<PermissionResult> ensureMicrophone({
    BuildContext? context,
    PermissionPolicy? policy,
  }) => _ensure(PermissionType.microphone, context: context, policy: policy);

  /// Speech recognition — a *separate* grant from [ensureMicrophone] on iOS,
  /// and the same underlying RECORD_AUDIO grant on Android (so on Android it
  /// resolves immediately once the microphone has been allowed).
  static Future<PermissionResult> ensureSpeechRecognition({
    BuildContext? context,
    PermissionPolicy? policy,
  }) => _ensure(
    PermissionType.speechRecognition,
    context: context,
    policy: policy,
  );

  static Future<PermissionResult> ensureContacts({
    BuildContext? context,
    PermissionPolicy? policy,
  }) => _ensure(PermissionType.contacts, context: context, policy: policy);

  static Future<PermissionResult> ensureBluetooth({
    BuildContext? context,
    PermissionPolicy? policy,
  }) => _ensure(PermissionType.bluetooth, context: context, policy: policy);

  /// Generic ensure — runs the full UX flow for any [PermissionType].
  ///
  /// Provide [explanation] to override the rationale dialog copy/icon for this
  /// call (already-localized strings).
  static Future<PermissionResult> ensure(
    PermissionType type, {
    BuildContext? context,
    PermissionPolicy? policy,
    PermissionExplanation? explanation,
  }) => _ensure(
    type,
    context: context,
    policy: policy,
    explanation: explanation,
  );

  // ---------------------------------------------------------------------------
  // PermissionFlow — higher-level declarative API
  // ---------------------------------------------------------------------------

  /// Runs a [PermissionFlow]: ensures the permission (check → rationale →
  /// request → settings redirect), then dispatches exactly one status callback.
  ///
  /// Returns the underlying [PermissionResult] so advanced flows can still
  /// inspect it if needed.
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
  static Future<PermissionResult> execute(PermissionFlow flow) async {
    final result = await _ensure(
      flow.permission,
      context: flow.context,
      policy: flow.policy,
      explanation: flow.explanation,
    );

    await _dispatch(flow, result.status);
    return result;
  }

  static Future<void> _dispatch(
    PermissionFlow flow,
    PermissionStatus status,
  ) async {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.provisional:
        await flow.onGranted?.call();
      case PermissionStatus.limited:
        // Prefer the limited-specific handler; fall back to granted.
        await (flow.onLimited ?? flow.onGranted)?.call();
      case PermissionStatus.denied:
      case PermissionStatus.unknown:
        await flow.onDenied?.call();
      case PermissionStatus.permanentlyDenied:
        await flow.onPermanentDenied?.call();
      case PermissionStatus.restricted:
        await flow.onRestricted?.call();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal ensure implementation
  // ---------------------------------------------------------------------------

  static Future<PermissionResult> _ensure(
    PermissionType type, {
    BuildContext? context,
    PermissionPolicy? policy,
    PermissionExplanation? explanation,
  }) async {
    final effectivePolicy = policy ?? _config.defaultPolicy;
    final theme = _theme;

    var result = await _service.check(type);

    if (result.isGranted) return result;

    // --- Denied: optionally show rationale before requesting ---
    if (result.isDenied) {
      if (effectivePolicy.showRationale && context != null && context.mounted) {
        final shouldRequest = await PermissionRationaleDialog.show(
          context: context,
          permissionType: type,
          theme: theme,
          explanation: explanation,
        );
        if (!shouldRequest) return result;
      }

      result = await _service.request(type);
    }

    if (result.isGranted) return result;

    // --- Permanently denied / restricted: offer settings redirect ---
    if (result.canOpenSettings) {
      if (effectivePolicy.autoOpenSettings) {
        await _service.openSettings();
      } else if (effectivePolicy.showSettingsDialog &&
          context != null &&
          context.mounted) {
        await PermissionSettingsDialog.show(
          context: context,
          permissionType: type,
          theme: theme,
          onOpenSettings: _service.openSettings,
          explanation: explanation,
        );
      }
    }

    return result;
  }
}
