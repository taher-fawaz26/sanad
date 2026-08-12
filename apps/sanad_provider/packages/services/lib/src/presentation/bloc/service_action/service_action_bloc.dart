import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/usecases/delete_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/set_provider_service_status_usecase.dart';

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
    required DeleteProviderServiceUseCase deleteProviderServiceUseCase,
    required SetProviderServiceStatusUseCase setProviderServiceStatusUseCase,
  }) : _deleteProviderServiceUseCase = deleteProviderServiceUseCase,
       _setProviderServiceStatusUseCase = setProviderServiceStatusUseCase,
       super(const ServiceActionState()) {
    on<ServiceDeleteRequestedEvent>(_onDelete);
    on<ServiceStatusToggleRequestedEvent>(_onStatusToggle);
    on<ServiceExternallyUpdatedEvent>(_onExternallyUpdated);
  }

  final DeleteProviderServiceUseCase _deleteProviderServiceUseCase;
  final SetProviderServiceStatusUseCase _setProviderServiceStatusUseCase;

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
    final result = await _deleteProviderServiceUseCase(event.serviceId).run();
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
    final result = await _setProviderServiceStatusUseCase(
      SetProviderServiceStatusParams(id: event.serviceId, status: event.status),
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

  void _onExternallyUpdated(
    ServiceExternallyUpdatedEvent event,
    Emitter<ServiceActionState> emit,
  ) => emit(
    ServiceActionState(
      status: RequestStatus.success,
      updatedService: event.service,
    ),
  );
}
