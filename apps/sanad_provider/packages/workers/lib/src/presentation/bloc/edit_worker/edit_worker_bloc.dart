import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/usecases/update_worker_usecase.dart';

part 'edit_worker_event.dart';
part 'edit_worker_state.dart';

/// Single-purpose bloc for the Edit Member form — mirrors `AddWorkerBloc`
/// but calls `UpdateWorkerUseCase` and surfaces the updated `WorkerEntity`
/// on success so the caller can refresh its local state.
class EditWorkerBloc extends Bloc<EditWorkerEvent, EditWorkerState> {
  EditWorkerBloc({required UpdateWorkerUseCase updateWorkerUseCase})
    : _updateWorkerUseCase = updateWorkerUseCase,
      super(const EditWorkerState()) {
    on<EditWorkerSubmitEvent>(_onSubmit);
  }

  final UpdateWorkerUseCase _updateWorkerUseCase;

  Future<void> _onSubmit(
    EditWorkerSubmitEvent event,
    Emitter<EditWorkerState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final result = await _updateWorkerUseCase(event.params).run();

    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (worker) => emit(
        state.copyWith(status: RequestStatus.success, updatedWorker: worker),
      ),
    );
  }
}
