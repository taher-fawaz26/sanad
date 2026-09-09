/// What a permission request came back as.
///
/// Mirrors the states the brief asks for while staying independent of
/// `permission_handler`: nothing here names a plugin type, so a bloc can
/// switch on it and a test can produce it without a platform channel.
enum AiPermissionOutcome {
  /// Go ahead.
  granted,

  /// Refused this time. Asking again is allowed.
  denied,

  /// Refused for good. Only the system settings screen can change it, so this
  /// is the only outcome that should surface an "Open settings" affordance.
  permanentlyDenied,

  /// The device has no such capability, or policy forbids it. Asking again
  /// will never help.
  unavailable
  ;

  /// Whether the caller may proceed.
  bool get isGranted => this == AiPermissionOutcome.granted;

  /// Whether the settings screen is the only remaining route.
  bool get needsSettings => this == AiPermissionOutcome.permanentlyDenied;
}

/// The single place this feature asks for a device permission.
///
/// Exists so no bloc, use case or widget touches `packages/permissions`
/// directly and — more importantly — so none of them needs a `BuildContext`
/// to ask. The implementation adapts the shared `Permissions` façade; the UI
/// reacts to the returned outcome instead of a dialog being raised from
/// business code.
abstract interface class AiPermissionGateway {
  /// Requests camera access.
  Future<AiPermissionOutcome> ensureCamera();

  /// Requests photo-library access.
  Future<AiPermissionOutcome> ensureGallery();

  /// Requests microphone access. Used by both recording and live voice.
  Future<AiPermissionOutcome> ensureMicrophone();

  /// Requests speech-recognition access.
  ///
  /// Separate from [ensureMicrophone] because iOS treats it as a separate
  /// grant with its own prompt. On Android it is the same underlying
  /// RECORD_AUDIO grant, so it resolves immediately once the microphone has
  /// been allowed — which is why dictation asks for both, in that order.
  Future<AiPermissionOutcome> ensureSpeechRecognition();

  /// Requests while-in-use location access.
  ///
  /// While-in-use, never background: the AI surface asks so it can find
  /// nearby branches during a conversation, and a background grant would be
  /// larger than anything the conversation justifies.
  Future<AiPermissionOutcome> ensureLocation();

  /// Requests notification permission.
  Future<AiPermissionOutcome> ensureNotifications();

  /// Opens the system settings screen for this app.
  ///
  /// Only meaningful after [AiPermissionOutcome.permanentlyDenied].
  Future<void> openSettings();
}
