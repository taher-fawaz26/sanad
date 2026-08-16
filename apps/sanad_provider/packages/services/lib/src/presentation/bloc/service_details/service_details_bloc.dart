import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/usecases/get_provider_service_usecase.dart';

part 'service_details_event.dart';
part 'service_details_state.dart';

/// Owns the Service Details read (`GET /provider-services/:id`).
///
/// Fetches the full, up-to-date service rather than trusting the row
/// `extra` passed in from the services list — the list endpoint's rows
/// carry only a subset of what this screen needs (e.g. only `primaryImage`,
/// not the full `images` array, and no `requests`/`revenue`).
class ServiceDetailsBloc
    extends Bloc<ServiceDetailsEvent, ServiceDetailsState> {
  ServiceDetailsBloc({
    required GetProviderServiceUseCase getProviderServiceUseCase,
  }) : _getProviderServiceUseCase = getProviderServiceUseCase,
       super(const ServiceDetailsState()) {
    on<ServiceDetailsFetchRequested>(_onFetch);
    on<ServiceDetailsExternallyUpdated>(_onExternallyUpdated);
  }

  final GetProviderServiceUseCase _getProviderServiceUseCase;

  Future<void> _onFetch(
    ServiceDetailsFetchRequested event,
    Emitter<ServiceDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RequestStatus.loading,
        serviceId: event.serviceId,
        clearFailure: true,
      ),
    );
    final result = await _getProviderServiceUseCase(event.serviceId).run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (service) => emit(
        ServiceDetailsState(status: RequestStatus.success, service: service),
      ),
    );
  }

  /// Folds in a service entity produced by an external mutation flow
  /// (status toggle / delete via `ServiceActionBloc`, or a saved edit) so
  /// this screen's canonical copy stays in sync without a redundant
  /// refetch.
  void _onExternallyUpdated(
    ServiceDetailsExternallyUpdated event,
    Emitter<ServiceDetailsState> emit,
  ) => emit(
    state.copyWith(status: RequestStatus.success, service: event.service),
  );
}
