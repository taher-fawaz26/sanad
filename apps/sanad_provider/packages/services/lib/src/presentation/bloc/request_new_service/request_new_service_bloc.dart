import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/usecases/create_service_request_usecase.dart';

part 'request_new_service_event.dart';
part 'request_new_service_state.dart';

/// Submits `POST /service-requests` for the Request New Service form.
class RequestNewServiceBloc
    extends Bloc<RequestNewServiceEvent, RequestNewServiceState> {
  RequestNewServiceBloc({
    required CreateServiceRequestUseCase createServiceRequestUseCase,
  }) : _createServiceRequestUseCase = createServiceRequestUseCase,
       super(const RequestNewServiceState()) {
    // Drop duplicate submits while one is in flight (double-tap guard),
    // matching AddServiceBloc/EditServiceBloc/ServiceActionBloc.
    on<RequestNewServiceSubmittedEvent>(_onSubmitted, transformer: droppable());
  }

  final CreateServiceRequestUseCase _createServiceRequestUseCase;

  Future<void> _onSubmitted(
    RequestNewServiceSubmittedEvent event,
    Emitter<RequestNewServiceState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    final result = await _createServiceRequestUseCase(event.params).run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (request) => emit(
        RequestNewServiceState(
          status: RequestStatus.success,
          createdRequest: request,
        ),
      ),
    );
  }
}
