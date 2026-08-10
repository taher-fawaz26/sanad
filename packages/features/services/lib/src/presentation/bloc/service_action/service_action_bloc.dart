import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/usecases/delete_service_usecase.dart';
import 'package:services/src/domain/usecases/update_service_status_usecase.dart';

part 'service_action_event.dart';
part 'service_action_state.dart';

/// Single-service mutations (delete / activate / deactivate) for the
/// services dashboard's per-card "more actions" sheet.
///
/// Kept separate from [ServicesListBloc] (which owns the list itself) so the
/// page can fold a successful mutation back into the list via
/// `ServiceReplacedInListEvent` / `ServiceRemovedFromListEvent`.
class ServiceActionBloc extends Bloc<ServiceActionEvent, ServiceActionState> {
  ServiceActionBloc({
    required DeleteServiceUseCase deleteServiceUseCase,
    required UpdateServiceStatusUseCase updateServiceStatusUseCase,
  }) : _deleteServiceUseCase = deleteServiceUseCase,
       _updateServiceStatusUseCase = updateServiceStatusUseCase,
       super(const ServiceActionState()) {
    on<ServiceDeleteRequestedEvent>(_onDelete);
    on<ServiceStatusToggleRequestedEvent>(_onStatusToggle);
  }

  final DeleteServiceUseCase _deleteServiceUseCase;
  final UpdateServiceStatusUseCase _updateServiceStatusUseCase;

  Future<void> _onDelete(
    ServiceDeleteRequestedEvent event,
    Emitter<ServiceActionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RequestStatus.loading,
        processingId: event.serviceId,
        clearFailure: true,
      ),
    );
    final result = await _deleteServiceUseCase(event.serviceId).run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (_) => emit(
        ServiceActionState(
          status: RequestStatus.success,
          deletedServiceId: event.serviceId,
        ),
      ),
    );
  }

  Future<void> _onStatusToggle(
    ServiceStatusToggleRequestedEvent event,
    Emitter<ServiceActionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RequestStatus.loading,
        processingId: event.serviceId,
        clearFailure: true,
      ),
    );
    final result = await _updateServiceStatusUseCase(
      UpdateServiceStatusParams(id: event.serviceId, isActive: event.isActive),
    ).run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (service) => emit(
        ServiceActionState(
          status: RequestStatus.success,
          updatedService: service,
        ),
      ),
    );
  }
}
