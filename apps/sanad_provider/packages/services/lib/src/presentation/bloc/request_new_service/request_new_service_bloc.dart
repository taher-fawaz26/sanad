import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/usecases/create_service_request_usecase.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';

part 'request_new_service_event.dart';
part 'request_new_service_state.dart';

/// Submits `POST /service-requests` for the Request New Service form, and
/// owns the `GET /categories` lookup backing its category picker.
class RequestNewServiceBloc
    extends Bloc<RequestNewServiceEvent, RequestNewServiceState> {
  RequestNewServiceBloc({
    required CreateServiceRequestUseCase createServiceRequestUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
  }) : _createServiceRequestUseCase = createServiceRequestUseCase,
       _getCategoriesUseCase = getCategoriesUseCase,
       super(const RequestNewServiceState()) {
    // Drop duplicate submits while one is in flight (double-tap guard),
    // matching AddServiceBloc/EditServiceBloc/ServiceActionBloc.
    on<RequestNewServiceSubmittedEvent>(_onSubmitted, transformer: droppable());
    on<RequestNewServiceCategoriesRequested>(
      _onCategoriesRequested,
      transformer: droppable(),
    );
  }

  final CreateServiceRequestUseCase _createServiceRequestUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;

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
        state.copyWith(
          status: RequestStatus.success,
          createdRequest: request,
        ),
      ),
    );
  }

  Future<void> _onCategoriesRequested(
    RequestNewServiceCategoriesRequested event,
    Emitter<RequestNewServiceState> emit,
  ) async {
    emit(
      state.copyWith(
        categoriesStatus: RequestNewServiceCategoriesStatus.loading,
        clearCategoriesFailure: true,
      ),
    );
    final result = await _getCategoriesUseCase(
      const GetCategoriesParams(limit: 100),
    ).run();
    result.fold(
      (failure) => emit(
        state.copyWith(
          categoriesStatus: RequestNewServiceCategoriesStatus.failure,
          categoriesFailure: failure,
        ),
      ),
      (paged) => emit(
        state.copyWith(
          categoriesStatus: RequestNewServiceCategoriesStatus.success,
          categories: paged.items,
        ),
      ),
    );
  }
}
