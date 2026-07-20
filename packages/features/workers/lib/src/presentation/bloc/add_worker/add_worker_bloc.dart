import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';

part 'add_worker_event.dart';
part 'add_worker_state.dart';

/// Single-purpose bloc for the Add Member form — status/failure only.
///
/// Follows the same shape as `AddBranchBloc` (status/failure, no draft
/// machinery) since Add Member is a single-step form, not a multi-step
/// wizard.
class AddWorkerBloc extends Bloc<AddWorkerEvent, AddWorkerState> {
  AddWorkerBloc({required InviteWorkerUseCase inviteWorkerUseCase})
    : _inviteWorkerUseCase = inviteWorkerUseCase,
      super(const AddWorkerState()) {
    on<AddWorkerSubmitEvent>(_onSubmit);
    on<AddWorkerResetEvent>(_onReset);
  }

  final InviteWorkerUseCase _inviteWorkerUseCase;

  Future<void> _onSubmit(
    AddWorkerSubmitEvent event,
    Emitter<AddWorkerState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final result = await _inviteWorkerUseCase(event.params).run();

    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (_) => emit(state.copyWith(status: RequestStatus.success)),
    );
  }

  void _onReset(AddWorkerResetEvent event, Emitter<AddWorkerState> emit) {
    emit(const AddWorkerState());
  }
}
