part of 'edit_service_bloc.dart';

sealed class EditServiceEvent extends Equatable {
  const EditServiceEvent();

  @override
  List<Object?> get props => [];
}

final class EditServiceSubmittedEvent extends EditServiceEvent {
  const EditServiceSubmittedEvent(this.params);

  final UpdateProviderServiceDescriptionParams params;

  @override
  List<Object?> get props => [params];
}
