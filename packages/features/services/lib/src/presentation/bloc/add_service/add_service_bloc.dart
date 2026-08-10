import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/usecases/create_service_usecase.dart';

part 'add_service_event.dart';
part 'add_service_state.dart';

/// Submits `POST /services` for the Add Service form.
class AddServiceBloc extends Bloc<AddServiceEvent, AddServiceState> {
  AddServiceBloc({required CreateServiceUseCase createServiceUseCase})
    : _createServiceUseCase = createServiceUseCase,
      super(const AddServiceState()) {
    on<AddServiceSubmittedEvent>(_onSubmitted);
  }

  final CreateServiceUseCase _createServiceUseCase;

  Future<void> _onSubmitted(
    AddServiceSubmittedEvent event,
    Emitter<AddServiceState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    final result = await _createServiceUseCase(event.params).run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (service) => emit(
        AddServiceState(status: RequestStatus.success, createdService: service),
      ),
    );
  }
}
