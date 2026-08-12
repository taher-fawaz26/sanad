part of 'provider_completion_bloc.dart';

sealed class ProviderCompletionEvent extends Equatable {
  const ProviderCompletionEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load.
final class ProviderCompletionLoaded extends ProviderCompletionEvent {
  const ProviderCompletionLoaded();
}

/// Re-fetches the setup-completion card (e.g. after returning from an
/// action that could change it).
final class ProviderCompletionRefreshed extends ProviderCompletionEvent {
  const ProviderCompletionRefreshed();
}
