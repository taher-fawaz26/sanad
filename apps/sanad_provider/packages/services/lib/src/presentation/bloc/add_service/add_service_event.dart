part of 'add_service_bloc.dart';

sealed class AddServiceEvent extends Equatable {
  const AddServiceEvent();

  @override
  List<Object?> get props => [];
}

final class AddServiceSubmittedEvent extends AddServiceEvent {
  const AddServiceSubmittedEvent(this.params);

  final CreateServiceParams params;

  @override
  List<Object?> get props => [params];
}
