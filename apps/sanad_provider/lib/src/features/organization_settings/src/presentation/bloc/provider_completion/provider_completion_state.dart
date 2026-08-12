part of 'provider_completion_bloc.dart';

class ProviderCompletionState extends Equatable {
  const ProviderCompletionState({
    this.status = RequestStatus.initial,
    this.completion,
    this.failure,
  });

  final RequestStatus status;
  final ProviderCompletionEntity? completion;
  final Failure? failure;

  bool get isLoading => status == RequestStatus.loading;
  bool get hasError => status == RequestStatus.failure;

  ProviderCompletionState copyWith({
    RequestStatus? status,
    ProviderCompletionEntity? completion,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ProviderCompletionState(
      status: status ?? this.status,
      completion: completion ?? this.completion,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, completion, failure];
}
