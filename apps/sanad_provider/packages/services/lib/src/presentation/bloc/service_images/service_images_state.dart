part of 'service_images_bloc.dart';

enum ServiceImagesAttachStatus { attaching, failed }

class ServiceImagesState extends Equatable {
  const ServiceImagesState({
    required this.service,
    this.attachStatus = const {},
    this.busyImageId,
    this.mutationFailure,
    this.failureNonce = 0,
  });

  /// Canonical, always-current service — every successful mutation replaces
  /// this with the backend's freshly-returned entity.
  final ProviderServiceEntity service;

  /// Attach phase for upload-succeeded items, keyed by
  /// `MediaUploadItem.localId`. Absent once attached (folded into
  /// [service]) or while the upload itself is still pending/uploading/
  /// failed (that lives in the sibling `MediaUploadBloc`'s own state).
  final Map<String, ServiceImagesAttachStatus> attachStatus;

  /// Row id of the committed image currently mid set-primary/delete, if
  /// any.
  final String? busyImageId;

  /// Most recent mutation failure, surfaced once via [failureNonce] — see
  /// its doc for why a plain field isn't enough on its own.
  final Failure? mutationFailure;

  /// Bumped on every new [mutationFailure] emission so a `BlocListener`
  /// reliably fires once per occurrence even if two failures in a row carry
  /// an identical message (which would otherwise compare equal and be
  /// skipped).
  final int failureNonce;

  ServiceImagesState copyWith({
    ProviderServiceEntity? service,
    Map<String, ServiceImagesAttachStatus>? attachStatus,
    String? busyImageId,
    bool clearBusyImageId = false,
    Failure? mutationFailure,
    int? failureNonce,
  }) => ServiceImagesState(
    service: service ?? this.service,
    attachStatus: attachStatus ?? this.attachStatus,
    busyImageId: clearBusyImageId ? null : (busyImageId ?? this.busyImageId),
    mutationFailure: mutationFailure ?? this.mutationFailure,
    failureNonce: failureNonce ?? this.failureNonce,
  );

  @override
  List<Object?> get props => [
    service,
    attachStatus,
    busyImageId,
    mutationFailure,
    failureNonce,
  ];
}
