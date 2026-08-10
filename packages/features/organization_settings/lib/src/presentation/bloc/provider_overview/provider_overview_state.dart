part of 'provider_overview_bloc.dart';

class ProviderOverviewState extends Equatable {
  const ProviderOverviewState({
    this.status = RequestStatus.initial,
    this.overview,
    this.failure,
  });

  final RequestStatus status;
  final ProviderOverviewEntity? overview;
  final Failure? failure;

  ProviderOverviewState copyWith({
    RequestStatus? status,
    ProviderOverviewEntity? overview,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ProviderOverviewState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, overview, failure];
}
