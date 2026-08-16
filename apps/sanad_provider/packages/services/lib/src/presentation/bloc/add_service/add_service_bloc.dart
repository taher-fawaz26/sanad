import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/usecases/browse_catalog_usecase.dart';
import 'package:services/src/domain/usecases/create_provider_service_usecase.dart';

part 'add_service_event.dart';
part 'add_service_state.dart';

/// Submits `POST /provider-services` for the Add Service form, and owns the
/// `GET /services` catalog lookup backing its service-name picker.
class AddServiceBloc extends Bloc<AddServiceEvent, AddServiceState> {
  AddServiceBloc({
    required CreateProviderServiceUseCase createProviderServiceUseCase,
    required BrowseCatalogUseCase browseCatalogUseCase,
  }) : _createProviderServiceUseCase = createProviderServiceUseCase,
       _browseCatalogUseCase = browseCatalogUseCase,
       super(const AddServiceState()) {
    // Drop duplicate submits while one is in flight (double-tap guard).
    on<AddServiceSubmittedEvent>(_onSubmitted, transformer: droppable());
    on<AddServiceCatalogRequested>(_onCatalogRequested, transformer: droppable());
  }

  final CreateProviderServiceUseCase _createProviderServiceUseCase;
  final BrowseCatalogUseCase _browseCatalogUseCase;

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
        state.copyWith(status: RequestStatus.success, createdService: service),
      ),
    );
  }

  Future<void> _onCatalogRequested(
    AddServiceCatalogRequested event,
    Emitter<AddServiceState> emit,
  ) async {
    emit(
      state.copyWith(
        catalogStatus: AddServiceCatalogStatus.loading,
        clearCatalogFailure: true,
      ),
    );
    final result = await _browseCatalogUseCase(
      const BrowseCatalogParams(limit: 100),
    ).run();
    result.fold(
      (failure) => emit(
        state.copyWith(
          catalogStatus: AddServiceCatalogStatus.failure,
          catalogFailure: failure,
        ),
      ),
      (paged) => emit(
        state.copyWith(
          catalogStatus: AddServiceCatalogStatus.success,
          catalogItems: paged.items,
        ),
      ),
    );
  }
}
