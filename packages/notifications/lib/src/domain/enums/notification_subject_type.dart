/// What a notification is about.
///
/// Paired with `subjectId`, this is the whole navigation contract: the same
/// pair rides on the in-app row and on the push payload, so one handler routes
/// every channel. Both fields are **nullable on the wire** — notifications that
/// predate deep links carry neither — which is why [unknown] exists and why
/// nothing may assume a tap is navigable.
enum NotificationSubjectType {
  /// A client service request. Opens that request's detail screen.
  clientRequest('CLIENT_REQUEST'),

  /// An offer inside a request. Opens the **offer thread within the request**,
  /// never a standalone offer screen — an offer has no meaning detached from
  /// the request it negotiates.
  requestOffer('REQUEST_OFFER'),

  /// Absent, or a subject this build does not know how to open. The tap opens
  /// the notification list instead of guessing a destination.
  unknown(null)
  ;

  const NotificationSubjectType(this._apiValue);

  final String? _apiValue;

  String? get apiValue => _apiValue;

  static NotificationSubjectType fromApi(String? raw) {
    if (raw == null) return NotificationSubjectType.unknown;
    final normalized = raw.trim().toUpperCase();
    for (final value in NotificationSubjectType.values) {
      if (value._apiValue == normalized) return value;
    }
    return NotificationSubjectType.unknown;
  }

  /// Whether this build knows a destination for the subject.
  bool get isNavigable => this != NotificationSubjectType.unknown;
}
