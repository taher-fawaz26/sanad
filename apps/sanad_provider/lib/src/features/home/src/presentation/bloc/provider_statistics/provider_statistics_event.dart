part of 'provider_statistics_bloc.dart';

sealed class ProviderStatisticsEvent extends Equatable {
  const ProviderStatisticsEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load.
final class ProviderStatisticsLoaded extends ProviderStatisticsEvent {
  const ProviderStatisticsLoaded();
}

/// Re-fetches the statistic cards (e.g. pull-to-refresh).
final class ProviderStatisticsRefreshed extends ProviderStatisticsEvent {
  const ProviderStatisticsRefreshed();
}
