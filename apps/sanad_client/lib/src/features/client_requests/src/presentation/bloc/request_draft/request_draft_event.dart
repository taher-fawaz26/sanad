part of 'request_draft_bloc.dart';

/// Base type for everything the draft composer reacts to.
sealed class RequestDraftEvent extends Equatable {
  /// Const so subclasses can be const.
  const RequestDraftEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads an existing request into the composer (edit flow).
final class RequestDraftLoaded extends RequestDraftEvent {
  /// Creates a load event for the request [id].
  const RequestDraftLoaded(this.id);

  /// The request to open in the composer.
  final String id;

  @override
  List<Object?> get props => [id];
}

/// The client picked a catalogue service.
final class RequestDraftServiceChanged extends RequestDraftEvent {
  /// Creates a service selection.
  const RequestDraftServiceChanged({
    required this.serviceId,
    required this.serviceName,
  });

  /// The catalogue service chosen.
  final String serviceId;

  /// Its display name, kept so the composer can show it without a
  /// second lookup.
  final String serviceName;

  @override
  List<Object?> get props => [serviceId, serviceName];
}

/// The client picked a job location.
final class RequestDraftLocationChanged extends RequestDraftEvent {
  /// Creates a location selection.
  const RequestDraftLocationChanged({
    required this.lat,
    required this.lng,
    this.addressLine,
  });

  /// Latitude of the chosen place.
  final double lat;

  /// Longitude of the chosen place.
  final double lng;

  /// The resolved street address, when geocoding produced one.
  final String? addressLine;

  @override
  List<Object?> get props => [lat, lng, addressLine];
}

/// The client picked a preferred start time.
final class RequestDraftPreferredAtChanged extends RequestDraftEvent {
  /// Creates a preferred-time change.
  const RequestDraftPreferredAtChanged(this.preferredAt);

  /// The requested start. Must be in the future at submit time.
  final DateTime preferredAt;

  @override
  List<Object?> get props => [preferredAt];
}

/// The client edited the job description.
final class RequestDraftNoteChanged extends RequestDraftEvent {
  /// Creates a note change.
  const RequestDraftNoteChanged(this.note);

  /// The description of the job.
  final String note;

  @override
  List<Object?> get props => [note];
}

/// Replaces the whole attachment set — the backend treats `mediaIds` as a
/// replacement, not an append.
final class RequestDraftMediaChanged extends RequestDraftEvent {
  /// Creates an attachment change.
  const RequestDraftMediaChanged(this.mediaIds);

  /// The complete attachment set, at most five ids.
  final List<String> mediaIds;

  @override
  List<Object?> get props => [mediaIds];
}

/// Saves without submitting. Valid at any level of completeness.
final class RequestDraftSaved extends RequestDraftEvent {
  /// Creates the save event.
  const RequestDraftSaved();
}

/// Saves, then submits for matching.
final class RequestDraftSubmitted extends RequestDraftEvent {
  /// Creates the submit event.
  const RequestDraftSubmitted();
}

/// Dismisses the structured submission-conflict banner.
final class RequestDraftConflictDismissed extends RequestDraftEvent {
  /// Creates the dismiss event.
  const RequestDraftConflictDismissed();
}
