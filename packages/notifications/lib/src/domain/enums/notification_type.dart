/// The backend's notification taxonomy.
///
/// Held as an enum so copy and iconography can branch on it, but every parse
/// falls back to [unknown]: the server adds types independently of app
/// releases, and an unrecognised type must still render its (server-rendered)
/// title and body rather than disappear.
///
/// One distinction is load-bearing in provider copy: [requestOfferLost] means
/// another provider won and this one was never personally judged, while
/// [requestOfferRejected] means the client explicitly declined *this* offer.
enum NotificationType {
  providerReviewApproved('PROVIDER_REVIEW_APPROVED'),
  providerReviewDocumentRequested('PROVIDER_REVIEW_DOCUMENT_REQUESTED'),
  providerReviewRejected('PROVIDER_REVIEW_REJECTED'),
  providerDetailsUpdatedByAdmin('PROVIDER_DETAILS_UPDATED_BY_ADMIN'),
  workerInvitedByAdmin('WORKER_INVITED_BY_ADMIN'),
  workerUpdatedByAdmin('WORKER_UPDATED_BY_ADMIN'),
  workerRemovedByAdmin('WORKER_REMOVED_BY_ADMIN'),
  workerInvitationResentByAdmin('WORKER_INVITATION_RESENT_BY_ADMIN'),
  workerInvitationCancelledByAdmin('WORKER_INVITATION_CANCELLED_BY_ADMIN'),
  adminMessageReceived('ADMIN_MESSAGE_RECEIVED'),
  complaintResolved('COMPLAINT_RESOLVED'),
  complaintDismissed('COMPLAINT_DISMISSED'),
  requestOfferReceived('REQUEST_OFFER_RECEIVED'),
  requestOfferWithdrawn('REQUEST_OFFER_WITHDRAWN'),
  requestCounterAccepted('REQUEST_COUNTER_ACCEPTED'),
  requestCounterDeclined('REQUEST_COUNTER_DECLINED'),
  requestJobStarted('REQUEST_JOB_STARTED'),
  requestAwaitingConfirmation('REQUEST_AWAITING_CONFIRMATION'),
  requestAutoCompleted('REQUEST_AUTO_COMPLETED'),
  requestExpired('REQUEST_EXPIRED'),
  requestCancelledByProvider('REQUEST_CANCELLED_BY_PROVIDER'),
  requestAutoCancelled('REQUEST_AUTO_CANCELLED'),
  requestMatched('REQUEST_MATCHED'),
  requestOfferCountered('REQUEST_OFFER_COUNTERED'),
  requestOfferAccepted('REQUEST_OFFER_ACCEPTED'),
  requestOfferRejected('REQUEST_OFFER_REJECTED'),
  requestOfferLost('REQUEST_OFFER_LOST'),
  requestCancelledByClient('REQUEST_CANCELLED_BY_CLIENT'),
  requestDisputed('REQUEST_DISPUTED'),

  /// A type this build has not seen. Still renders — the server already wrote
  /// the title and body in the recipient's language.
  unknown(null)
  ;

  const NotificationType(this._apiValue);

  final String? _apiValue;

  String? get apiValue => _apiValue;

  static NotificationType fromApi(String? raw) {
    if (raw == null) return NotificationType.unknown;
    final normalized = raw.trim().toUpperCase();
    for (final value in NotificationType.values) {
      if (value._apiValue == normalized) return value;
    }
    return NotificationType.unknown;
  }

  /// Whether this notification signals that a request's server-side state
  /// moved, so an open request screen should re-read it.
  ///
  /// Covers the timer-driven transitions the app deliberately does not model
  /// locally — expiry, job start, auto-cancel and auto-complete.
  bool get invalidatesRequestState => switch (this) {
    requestMatched ||
    requestOfferReceived ||
    requestOfferWithdrawn ||
    requestOfferCountered ||
    requestOfferAccepted ||
    requestOfferRejected ||
    requestOfferLost ||
    requestCounterAccepted ||
    requestCounterDeclined ||
    requestJobStarted ||
    requestAwaitingConfirmation ||
    requestAutoCompleted ||
    requestExpired ||
    requestAutoCancelled ||
    requestCancelledByProvider ||
    requestCancelledByClient ||
    requestDisputed => true,
    _ => false,
  };
}
