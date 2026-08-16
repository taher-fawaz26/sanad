import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/usecases/get_service_request_usecase.dart';

part 'request_details_event.dart';
part 'request_details_state.dart';

/// Owns the Request Details read (`GET /service-requests/:id`).
///
/// Seeded from the list row passed via the route `extra` — it carries the
/// status/dates but not `description`/`rejectionReason`/`images` — then
/// fetches the full detail on construction so the screen can skeletonize
/// only the fields the row didn't already have.
class RequestDetailsBloc
    extends Bloc<RequestDetailsEvent, RequestDetailsState> {
  RequestDetailsBloc({
    required GetServiceRequestUseCase getServiceRequestUseCase,
    required ServiceRequestEntity initialRequest,
  }) : _getServiceRequestUseCase = getServiceRequestUseCase,
       super(RequestDetailsState(request: initialRequest)) {
    on<RequestDetailsFetchRequested>(_onFetch);
  }

  final GetServiceRequestUseCase _getServiceRequestUseCase;

  Future<void> _onFetch(
    RequestDetailsFetchRequested event,
    Emitter<RequestDetailsState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    final result = await _getServiceRequestUseCase(state.request.id).run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (detail) => emit(
        RequestDetailsState(status: RequestStatus.success, request: detail),
      ),
    );
  }
}
