part of 'edit_worker_bloc.dart';

sealed class EditWorkerEvent extends Equatable {
  const EditWorkerEvent();

  @override
  List<Object?> get props => [];
}

final class EditWorkerSubmitEvent extends EditWorkerEvent {
  const EditWorkerSubmitEvent(this.params);

  final UpdateWorkerParams params;

  @override
  List<Object?> get props => [params];
}
