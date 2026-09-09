part of 'request_draft_bloc.dart';

/// The composer's working copy of a request.
///
/// Holds what the user has entered, which is not the same as what the server
/// has stored — [isDirty] is the difference. Every field is nullable because a
/// draft is meant to be saveable half-finished.
class RequestDraftState extends Equatable {
  /// Creates a composer state.
  const RequestDraftState({
    this.requestId,
    this.status = ClientRequestStatus.draft,
    this.serviceId,
    this.serviceName,
    this.lat,
    this.lng,
    this.addressLine,
    this.preferredAt,
    this.note,
    this.mediaIds = const [],
    this.mediaIdsResolved = false,
    this.isDirty = false,
    this.loadStatus = RequestStatus.initial,
    this.loadFailure,
    this.saveStatus = RequestStatus.initial,
    this.saveFailure,
    this.submitStatus = RequestStatus.initial,
    this.submitFailure,
    this.submissionConflict,
  });

  /// Seeds the composer from a server request, or an empty draft for `null`.
  factory RequestDraftState.fromRequest(ClientRequest? request) {
    if (request == null) return const RequestDraftState();
    return RequestDraftState(
      requestId: request.id,
      status: request.status,
      serviceId: request.serviceId,
      serviceName: request.serviceName,
      lat: request.lat,
      lng: request.lng,
      addressLine: request.addressLine,
      preferredAt: request.preferredAt,
      note: request.note,
      mediaIds: request.attachments.map((e) => e.mediaId).toList(),
      mediaIdsResolved: true,
    );
  }

  /// `null` until the first save creates the draft server-side.
  final String? requestId;

  /// The server's status for this request.
  ///
  /// The backend allows editing a submitted request only while no offer is
  /// awaiting a reply, and answers `409` otherwise — so this being `draft` is
  /// not a licence to assume the edit will succeed.
  final ClientRequestStatus status;

  /// The chosen catalogue service.
  final String? serviceId;

  /// Its display name, for the summary row.
  final String? serviceName;

  /// Latitude of the chosen place.
  final double? lat;

  /// Longitude of the chosen place.
  final double? lng;

  /// The street address entered or geocoded.
  final String? addressLine;

  /// The requested start time.
  final DateTime? preferredAt;

  /// The description of the job.
  final String? note;

  /// Attachment ids, at most five. Replaces the set on save.
  final List<String> mediaIds;

  /// Whether [mediaIds] reflects a real attachment set — seeded from the
  /// server or chosen by the user — rather than the empty default.
  ///
  /// `mediaIds` **replaces** the whole set server-side, so a brand-new
  /// composer that has never touched attachments must omit the key entirely.
  /// Sending `[]` from an unrelated save would silently detach every file.
  final bool mediaIdsResolved;

  /// Whether the on-screen values differ from the last server response.
  final bool isDirty;

  /// Lifecycle of the initial read.
  final RequestStatus loadStatus;

  /// Why the read failed, if it did.
  final Failure? loadFailure;

  /// Lifecycle of the last save.
  final RequestStatus saveStatus;

  /// Why the save failed, if it did.
  final Failure? saveFailure;

  /// Lifecycle of the last submit.
  final RequestStatus submitStatus;

  /// Why the submit failed, if it did.
  final Failure? submitFailure;

  /// The structured reason a submit was refused, when it was refused for a
  /// matching reason. Drives code-specific recovery UI.
  final RequestSubmissionConflict? submissionConflict;

  /// Whether a place has been chosen.
  bool get hasLocation => lat != null && lng != null;

  /// Everything submit requires. The server re-checks, so this only gates the
  /// button — it never replaces handling the server's answer.
  bool get canSubmit => serviceId != null && hasLocation && preferredAt != null;

  /// Which required fields are still missing, for the composer to point at.
  List<String> get missingForSubmit => [
    if (serviceId == null) 'serviceId',
    if (!hasLocation) 'location',
    if (preferredAt == null) 'preferredAt',
  ];

  /// Client-side check for a past `preferredAt`, which the server rejects with
  /// a `400`. Returns an i18n key, or `null` when acceptable.
  String? get preferredAtError =>
      preferredAt == null ? null : RequestValidators.futureInstant(preferredAt);

  /// Whether a submit is in flight.
  bool get isSubmitting => submitStatus == RequestStatus.loading;

  /// Whether a save is in flight.
  bool get isSaving => saveStatus == RequestStatus.loading;

  /// Returns a copy with the given fields replaced.
  RequestDraftState copyWith({
    String? requestId,
    ClientRequestStatus? status,
    String? serviceId,
    String? serviceName,
    double? lat,
    double? lng,
    String? addressLine,
    DateTime? preferredAt,
    String? note,
    List<String>? mediaIds,
    bool? mediaIdsResolved,
    bool? isDirty,
    RequestStatus? loadStatus,
    Failure? loadFailure,
    RequestStatus? saveStatus,
    Failure? saveFailure,
    bool clearSaveFailure = false,
    RequestStatus? submitStatus,
    Failure? submitFailure,
    bool clearSubmitFailure = false,
    RequestSubmissionConflict? submissionConflict,
    bool clearSubmissionConflict = false,
  }) => RequestDraftState(
    requestId: requestId ?? this.requestId,
    status: status ?? this.status,
    serviceId: serviceId ?? this.serviceId,
    serviceName: serviceName ?? this.serviceName,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    addressLine: addressLine ?? this.addressLine,
    preferredAt: preferredAt ?? this.preferredAt,
    note: note ?? this.note,
    mediaIds: mediaIds ?? this.mediaIds,
    mediaIdsResolved: mediaIdsResolved ?? this.mediaIdsResolved,
    isDirty: isDirty ?? this.isDirty,
    loadStatus: loadStatus ?? this.loadStatus,
    loadFailure: loadFailure ?? this.loadFailure,
    saveStatus: saveStatus ?? this.saveStatus,
    saveFailure: clearSaveFailure ? null : (saveFailure ?? this.saveFailure),
    submitStatus: submitStatus ?? this.submitStatus,
    submitFailure: clearSubmitFailure
        ? null
        : (submitFailure ?? this.submitFailure),
    submissionConflict: clearSubmissionConflict
        ? null
        : (submissionConflict ?? this.submissionConflict),
  );

  @override
  List<Object?> get props => [
    requestId,
    status,
    serviceId,
    serviceName,
    lat,
    lng,
    addressLine,
    preferredAt,
    note,
    mediaIds,
    mediaIdsResolved,
    isDirty,
    loadStatus,
    loadFailure,
    saveStatus,
    saveFailure,
    submitStatus,
    submitFailure,
    submissionConflict,
  ];
}
