import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/usecases/create_provider_service_usecase.dart';

part 'add_service_event.dart';
part 'add_service_state.dart';

/// Submits `POST /provider-services` for the Add Service form.
class AddServiceBloc extends Bloc<AddServiceEvent, AddServiceState> {
  AddServiceBloc({
    required CreateProviderServiceUseCase createProviderServiceUseCase,
  }) : _createProviderServiceUseCase = createProviderServiceUseCase,
       super(const AddServiceState()) {
    // Drop duplicate submits while one is in flight (double-tap guard).
    on<AddServiceSubmittedEvent>(_onSubmitted, transformer: droppable());
  }

  final CreateProviderServiceUseCase _createProviderServiceUseCase;

  Future<void> _onSubmitted(
    AddServiceSubmittedEvent event,
    Emitter<AddServiceState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    final result = await _createProviderServiceUseCase(event.params).run();
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
