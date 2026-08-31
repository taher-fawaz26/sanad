/// Runtime state of the local authentication gate.
///
/// This is the *gate*, not the preference: whether the lock is switched on is
/// persisted separately (see `AppLockRepository.isEnabled`), and this state is
/// derived from it at every cold start. It is never persisted.
///
/// The set is deliberately small. Attempt outcomes (failed, locked out, …) are
/// **not** states — after any unsuccessful attempt the gate is simply still
/// [locked], with the last status carried alongside purely to choose the copy
/// shown to the user.
enum AppLockState {
  /// Startup value, before the preference and capability have been read.
  /// Nothing protected may render, and no prompt may be raised, while in this
  /// state.
  unknown,

  /// The gate is open: either it is switched off, there is no session to
  /// protect, or the user has just authenticated.
  unlocked,

  /// Protected content must not render. A prompt may be raised from here.
  locked,

  /// An OS prompt is currently on screen. Doubles as the re-entrancy guard —
  /// no second `authenticate()` may start while in this state.
  authenticating,

  /// The preference is on, but the device can no longer authenticate anyone
  /// (screen lock removed). Fails **open**: the session is still protected by
  /// tokens and routing, and failing closed here would permanently lock the
  /// user out of an app no credential can open.
  unavailable,
}
