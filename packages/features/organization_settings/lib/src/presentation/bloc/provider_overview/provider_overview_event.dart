part of 'provider_overview_bloc.dart';

sealed class ProviderOverviewEvent extends Equatable {
  const ProviderOverviewEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load.
final class ProviderOverviewLoaded extends ProviderOverviewEvent {
  const ProviderOverviewLoaded();
}

/// Re-fetches the KPI-hub counts (e.g. pull-to-refresh).
final class ProviderOverviewRefreshed extends ProviderOverviewEvent {
  const ProviderOverviewRefreshed();
}
