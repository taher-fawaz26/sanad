part of 'provider_request_detail_bloc.dart';

/// One provider-view request, plus the state of the read and of the last
/// action taken on it.
class ProviderRequestDetailState extends Equatable {
  /// Creates the detail state.
  const ProviderRequestDetailState({
    this.request,
    this.loadStatus = RequestStatus.initial,
    this.loadFailure,
    this.mutationStatus = RequestStatus.initial,
    this.mutationFailure,
  });

  /// The server's request, or `null` before the first load.
  final ProviderRequest? request;

  /// Lifecycle of the read.
  final RequestStatus loadStatus;

  /// Why the read failed, if it did.
  final Failure? loadFailure;

  /// Lifecycle of the most recent action.
  final RequestStatus mutationStatus;

  /// Why that action failed, if it did.
  final Failure? mutationFailure;

  /// Whether the first read is still in flight.
  bool get isLoading => loadStatus == RequestStatus.loading && request == null;

  /// Whether an action is in flight.
  bool get isMutating => mutationStatus == RequestStatus.loading;

  /// Returns a copy with the given fields replaced.
  ProviderRequestDetailState copyWith({
    ProviderRequest? request,
    RequestStatus? loadStatus,
    Failure? loadFailure,
    RequestStatus? mutationStatus,
    Failure? mutationFailure,
    bool clearMutationFailure = false,
  }) => ProviderRequestDetailState(
    request: request ?? this.request,
    loadStatus: loadStatus ?? this.loadStatus,
    loadFailure: loadFailure ?? this.loadFailure,
    mutationStatus: mutationStatus ?? this.mutationStatus,
    mutationFailure: clearMutationFailure
        ? null
        : (mutationFailure ?? this.mutationFailure),
  );

  @override
  List<Object?> get props => [
    request,
    loadStatus,
    loadFailure,
    mutationStatus,
    mutationFailure,
  ];
}
