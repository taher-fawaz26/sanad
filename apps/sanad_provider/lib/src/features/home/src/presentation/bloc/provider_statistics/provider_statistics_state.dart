part of 'provider_statistics_bloc.dart';

class ProviderStatisticsState extends Equatable {
  const ProviderStatisticsState({
    this.status = RequestStatus.initial,
    this.statistics = const [],
    this.failure,
  });

  final RequestStatus status;
  final List<ProviderStatisticEntity> statistics;
  final Failure? failure;

  ProviderStatisticsState copyWith({
    RequestStatus? status,
    List<ProviderStatisticEntity>? statistics,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ProviderStatisticsState(
      status: status ?? this.status,
      statistics: statistics ?? this.statistics,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, statistics, failure];
}
