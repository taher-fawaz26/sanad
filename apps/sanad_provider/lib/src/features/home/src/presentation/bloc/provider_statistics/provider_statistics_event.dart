part of 'provider_statistics_bloc.dart';

sealed class ProviderStatisticsEvent extends Equatable {
  const ProviderStatisticsEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load — serves fresh cached data without a network call.
final class ProviderStatisticsLoaded extends ProviderStatisticsEvent {
  const ProviderStatisticsLoaded();
}

/// Force a re-fetch (pull-to-refresh, return-from-action, or locale change),
/// bypassing the "fresh cache" short-circuit.
final class ProviderStatisticsRefreshed extends ProviderStatisticsEvent {
  const ProviderStatisticsRefreshed();
}
