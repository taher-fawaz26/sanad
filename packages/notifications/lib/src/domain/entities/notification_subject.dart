import 'package:equatable/equatable.dart';
import 'package:notifications/src/domain/enums/notification_subject_type.dart';

/// The navigation coordinates carried by a notification.
///
/// This is the shared half of tap handling: both the in-app row and the FCM
/// payload produce one of these, and only the *destination* differs by app
/// role. Parsing lives here so a client and a provider cannot drift on what a
/// subject means.
class NotificationSubject extends Equatable {
  const NotificationSubject({
    required this.type,
    this.id,
    this.metadata = const {},
  });

  /// Nothing to open — an older notification with no subject, or a subject
  /// this build does not recognise.
  static const NotificationSubject none = NotificationSubject(
    type: NotificationSubjectType.unknown,
  );

  final NotificationSubjectType type;

  /// `subjectId`. For [NotificationSubjectType.clientRequest] this is the
  /// request; for [NotificationSubjectType.requestOffer] it is the **offer**.
  final String? id;

  /// Optional display and routing extras, e.g. `requestId`, `serviceName`.
  final Map<String, dynamic> metadata;

  /// The request to open.
  ///
  /// For an offer subject the request id is not `subjectId` — it lives in
  /// `metadata.requestId`, which the contract marks optional. When it is
  /// missing there is genuinely nothing to open, and the caller must fall back
  /// to the notification list rather than guess.
  String? get requestId {
    if (type == NotificationSubjectType.clientRequest) return _nonEmpty(id);
    if (type == NotificationSubjectType.requestOffer) {
      return _nonEmpty(metadata['requestId']?.toString()) ??
          _nonEmpty(metadata['request_id']?.toString());
    }
    return null;
  }

  /// The offer thread to focus inside the request, when the subject is an
  /// offer.
  String? get offerId => type == NotificationSubjectType.requestOffer
      ? _nonEmpty(id) ?? _nonEmpty(metadata['offerId']?.toString())
      : null;

  /// A display extra the server attached, e.g. the service name.
  String? get serviceName => _nonEmpty(metadata['serviceName']?.toString());

  /// Whether a tap has somewhere to go.
  ///
  /// An offer subject with no `requestId` is **not** navigable: the offer
  /// thread lives inside a request, and without the request there is no screen.
  bool get isNavigable => type.isNavigable && requestId != null;

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props => [type, id, metadata];
}
