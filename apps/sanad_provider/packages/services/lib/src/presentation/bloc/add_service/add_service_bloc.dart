import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/usecases/browse_catalog_usecase.dart';
import 'package:services/src/domain/usecases/create_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';

part 'add_service_event.dart';
part 'add_service_state.dart';

/// Submits `POST /provider-services` for the Add Service form, and owns the
/// `GET /categories` and category-scoped `GET /services?categoryId=` lookups
/// backing its Category → Service picker pair (SAN-577: the two-step
/// dependency — a category must be chosen before its services can be
/// browsed/selected).
class AddServiceBloc extends Bloc<AddServiceEvent, AddServiceState> {
  AddServiceBloc({
    required CreateProviderServiceUseCase createProviderServiceUseCase,
    required BrowseCatalogUseCase browseCatalogUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
  }) : _createProviderServiceUseCase = createProviderServiceUseCase,
       _browseCatalogUseCase = browseCatalogUseCase,
       _getCategoriesUseCase = getCategoriesUseCase,
       super(const AddServiceState()) {
    // Drop duplicate submits while one is in flight (double-tap guard).
    on<AddServiceSubmittedEvent>(_onSubmitted, transformer: droppable());
    on<AddServiceCategoriesRequested>(
      _onCategoriesRequested,
      transformer: droppable(),
    );
    on<AddServiceCatalogRequested>(
      _onCatalogRequested,
      transformer: droppable(),
    );
  }

  final CreateProviderServiceUseCase _createProviderServiceUseCase;
  final BrowseCatalogUseCase _browseCatalogUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;

  Future<void> _onSubmitted(
    AddServiceSubmittedEvent event,
    Emitter<AddServiceState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    // TEMP DIAGNOSTIC (Create Service timeout investigation) — debug-only,
    // logs no tokens/body/PII. Remove once the timing-out phase is
    // confirmed.
    final stopwatch = kDebugMode ? Stopwatch() : null;
    stopwatch?.start();
    final result = await _createProviderServiceUseCase(event.params).run();
    if (kDebugMode) {
      stopwatch?.stop();
      result.fold(
        (failure) => debugPrint(
          '[CreateService] elapsedMs=${stopwatch?.elapsedMilliseconds} '
          'failure=${failure.runtimeType} code=${failure.code} '
          'phase=${failure.metadata?['phase']}',
        ),
        (_) => debugPrint(
          '[CreateService] elapsedMs=${stopwatch?.elapsedMilliseconds} '
          'success',
        ),
      );
    }
    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (service) => emit(
        state.copyWith(status: RequestStatus.success, createdService: service),
      ),
    );
  }

  Future<void> _onCategoriesRequested(
    AddServiceCategoriesRequested event,
    Emitter<AddServiceState> emit,
  ) async {
    emit(
      state.copyWith(
        categoriesStatus: AddServiceCategoriesStatus.loading,
        clearCategoriesFailure: true,
      ),
    );
    final result = await _getCategoriesUseCase(
      const GetCategoriesParams(limit: 100),
    ).run();
    result.fold(
      (failure) => emit(
        state.copyWith(
          categoriesStatus: AddServiceCategoriesStatus.failure,
          categoriesFailure: failure,
        ),
      ),
      (paged) => emit(
        state.copyWith(
          categoriesStatus: AddServiceCategoriesStatus.success,
          categories: paged.items,
        ),
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
      BrowseCatalogParams(limit: 100, categoryId: event.categoryId),
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
