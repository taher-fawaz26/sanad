part of 'add_worker_bloc.dart';

sealed class AddWorkerEvent extends Equatable {
  const AddWorkerEvent();

  @override
  List<Object?> get props => [];
}

final class AddWorkerSubmitEvent extends AddWorkerEvent {
  const AddWorkerSubmitEvent(this.params);

  final InviteWorkerParams params;

  @override
  List<Object?> get props => [params];
}
