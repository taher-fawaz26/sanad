part of 'identity_header_bloc.dart';

sealed class IdentityHeaderEvent extends Equatable {
  const IdentityHeaderEvent();

  @override
  List<Object?> get props => [];
}

/// Seeds the current cover/logo URLs (e.g. from the loaded profile).
final class IdentityHeaderInitialized extends IdentityHeaderEvent {
  const IdentityHeaderInitialized({this.coverUrl, this.logoUrl});

  final String? coverUrl;
  final String? logoUrl;

  @override
  List<Object?> get props => [coverUrl, logoUrl];
}

/// A freshly edited image is ready to upload for [slot].
final class IdentityHeaderMediaSelected extends IdentityHeaderEvent {
  const IdentityHeaderMediaSelected({required this.slot, required this.media});

  final OrganizationMediaSlot slot;
  final EditedMedia media;

  @override
  List<Object?> get props => [slot, media];
}

/// Retry the last failed upload for [slot].
final class IdentityHeaderUploadRetried extends IdentityHeaderEvent {
  const IdentityHeaderUploadRetried({required this.slot});

  final OrganizationMediaSlot slot;

  @override
  List<Object?> get props => [slot];
}

/// Cancel an in-flight upload for [slot].
final class IdentityHeaderUploadCancelled extends IdentityHeaderEvent {
  const IdentityHeaderUploadCancelled({required this.slot});

  final OrganizationMediaSlot slot;

  @override
  List<Object?> get props => [slot];
}

/// Remove the current image for [slot] (already user-confirmed).
final class IdentityHeaderMediaRemoved extends IdentityHeaderEvent {
  const IdentityHeaderMediaRemoved({required this.slot});

  final OrganizationMediaSlot slot;

  @override
  List<Object?> get props => [slot];
}
