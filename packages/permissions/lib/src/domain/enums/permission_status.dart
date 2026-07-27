/// Our own permission status model — permission_handler types are never exposed
/// outside the infrastructure layer.
enum PermissionStatus {
  /// The user explicitly granted the permission.
  granted,

  /// The user denied the permission; the app may still request it again.
  denied,

  /// The user selected "Don't ask again" (Android) or denied twice (iOS).
  /// The only recovery path is directing the user to app settings.
  permanentlyDenied,

  /// An OS-level restriction prevents the user from granting this permission
  /// (parental controls, MDM / enterprise policy).
  restricted,

  /// iOS only — the user granted access to a limited subset of the resource
  /// (e.g. a selection of photos instead of the full library).
  limited,

  /// iOS only — the permission was provisionally granted; notifications are
  /// delivered silently until the user explicitly allows or denies them.
  provisional,

  /// The status could not be determined.
  unknown,
}
