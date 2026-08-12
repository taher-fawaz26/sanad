import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/usecases/update_provider_service_description_usecase.dart';

part 'edit_service_event.dart';
part 'edit_service_state.dart';

/// Submits `PATCH /provider-services/{id}` (description only) for the Edit
/// Service form.
class EditServiceBloc extends Bloc<EditServiceEvent, EditServiceState> {
  EditServiceBloc({
    required UpdateProviderServiceDescriptionUseCase
    updateProviderServiceDescriptionUseCase,
  }) : _updateProviderServiceDescriptionUseCase =
           updateProviderServiceDescriptionUseCase,
       super(const EditServiceState()) {
    on<EditServiceSubmittedEvent>(_onSubmitted);
  }

  final UpdateProviderServiceDescriptionUseCase
  _updateProviderServiceDescriptionUseCase;

  Future<void> _onSubmitted(
    EditServiceSubmittedEvent event,
    Emitter<EditServiceState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    final result = await _updateProviderServiceDescriptionUseCase(
      event.params,
    ).run();
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
