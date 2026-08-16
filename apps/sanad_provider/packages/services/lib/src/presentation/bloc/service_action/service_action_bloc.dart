import 'package:bloc_concurrency/bloc_concurrency.dart';
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
/// services dashboard's per-card "more actions" sheet — and, via
/// [ServiceExternallyUpdatedEvent], the **single reconciliation hub** for
/// every other flow that produces a fresh [ProviderServiceEntity]:
///
/// ```text
/// EditServiceBloc (description) ┐
/// ServiceImagesBloc (images)    ┼─▶ EditServicePage pops the entity
/// (nothing changed → pops null) ┘        │
///                                        ▼
///              service_action_invokers.confirmAndEditService
///                                        │ ServiceExternallyUpdatedEvent
///                                        ▼
///                                 ServiceActionBloc (this bloc)
///                                  │                        │
///                    BlocListener │                        │ BlocListener
///                 (services_page) ▼                        ▼ (service_details_page)
///                      ServicesListBloc              ServiceDetailsBloc
///                (ServiceReplacedInListEvent)  (ServiceDetailsExternallyUpdated)
/// ```
///
/// `ServiceActionBloc` is instantiated once per screen (My Services list,
/// and separately per Service Details visit) — "single hub" means a single
/// *event*, not a single bloc instance; each screen's own instance still
/// reconciles independently. Kept separate from [ServicesListBloc] (which
/// owns the list itself) precisely so this bridging role stays in one
/// place instead of every mutation surface reinventing its own
/// list/detail-sync logic.
class ServiceActionBloc extends Bloc<ServiceActionEvent, ServiceActionState> {
  ServiceActionBloc({
    required DeleteProviderServiceUseCase deleteProviderServiceUseCase,
    required SetProviderServiceStatusUseCase setProviderServiceStatusUseCase,
  }) : _deleteProviderServiceUseCase = deleteProviderServiceUseCase,
       _setProviderServiceStatusUseCase = setProviderServiceStatusUseCase,
       super(const ServiceActionState()) {
    // Drop duplicate submits while one is in flight (double-tap guard).
    on<ServiceDeleteRequestedEvent>(_onDelete, transformer: droppable());
    on<ServiceStatusToggleRequestedEvent>(
      _onStatusToggle,
      transformer: droppable(),
    );
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
