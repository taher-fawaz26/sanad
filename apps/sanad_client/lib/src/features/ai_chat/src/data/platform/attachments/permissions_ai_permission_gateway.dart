import 'package:permissions/permissions.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';

/// Adapts the shared `Permissions` façade to this feature's outcome model.
///
/// The only file in the AI chat feature that names `packages/permissions`.
/// Everything above it switches on [AiPermissionOutcome], which means a bloc
/// test needs no plugin, no platform channel and no `BuildContext`.
///
/// ## No context, on purpose
///
/// `Permissions.ensure` accepts an optional `BuildContext` and, when given
/// one, raises its own rationale and settings dialogs. It is deliberately not
/// passed here: business code holding a `BuildContext` is how async gaps turn
/// into "used across an await" bugs, and it would put UI decisions inside a
/// bloc. Without a context the façade still checks, still prompts the system
/// dialog, and still reports the outcome — the app then decides what to show,
/// in the widget layer, from state.
final class PermissionsAiPermissionGateway implements AiPermissionGateway {
  /// Creates the gateway.
  const PermissionsAiPermissionGateway();

  @override
  Future<AiPermissionOutcome> ensureCamera() => _ensure(PermissionType.camera);

  @override
  Future<AiPermissionOutcome> ensureGallery() =>
      _ensure(PermissionType.gallery);

  @override
  Future<AiPermissionOutcome> ensureMicrophone() =>
      _ensure(PermissionType.microphone);

  @override
  Future<AiPermissionOutcome> ensureSpeechRecognition() =>
      _ensure(PermissionType.speechRecognition);

  @override
  Future<void> openSettings() => Permissions.openSettings();

  Future<AiPermissionOutcome> _ensure(PermissionType type) async {
    final result = await Permissions.ensure(type);
    return mapPermissionResult(result);
  }

  /// Translates a shared [PermissionResult] into an [AiPermissionOutcome].
  ///
  /// Exposed so the mapping is testable without a platform channel — it is the
  /// part with actual decisions in it.
  static AiPermissionOutcome mapPermissionResult(PermissionResult result) {
    // `isGranted` is true for `limited` and `provisional` too. Limited photo
    // access is a real grant: the user picked *some* photos to share, and the
    // picker will show exactly those. Treating it as a refusal would leave
    // them staring at a permission prompt they already answered.
    if (result.isGranted) return AiPermissionOutcome.granted;
    if (result.isPermanentlyDenied) {
      return AiPermissionOutcome.permanentlyDenied;
    }
    // Restricted means policy forbids it — parental controls, MDM. Asking
    // again will never help, and the settings screen cannot fix it either.
    if (result.isRestricted) return AiPermissionOutcome.unavailable;
    return AiPermissionOutcome.denied;
  }
}
