import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/usecases/update_service_usecase.dart';

part 'edit_service_event.dart';
part 'edit_service_state.dart';

/// Submits `PATCH /services/{id}` for the Edit Service form.
class EditServiceBloc extends Bloc<EditServiceEvent, EditServiceState> {
  EditServiceBloc({required UpdateServiceUseCase updateServiceUseCase})
    : _updateServiceUseCase = updateServiceUseCase,
      super(const EditServiceState()) {
    on<EditServiceSubmittedEvent>(_onSubmitted);
  }

  final UpdateServiceUseCase _updateServiceUseCase;

  Future<void> _onSubmitted(
    EditServiceSubmittedEvent event,
    Emitter<EditServiceState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    final result = await _updateServiceUseCase(event.params).run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (service) => emit(
        EditServiceState(
          status: RequestStatus.success,
          updatedService: service,
        ),
      ),
    );
  }
}
