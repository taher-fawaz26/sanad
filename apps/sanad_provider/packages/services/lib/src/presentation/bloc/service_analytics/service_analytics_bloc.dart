import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/provider_service_overview_entity.dart';
import 'package:services/src/domain/usecases/get_provider_services_overview_usecase.dart';

part 'service_analytics_event.dart';
part 'service_analytics_state.dart';

/// Loads `GET /provider-services/overview` for the dashboard KPI cards.
///
/// The live backend always returns `dataAvailable: false` today — the
/// state exposes that flag as-is so the presentation layer can show a "not
/// available yet" placeholder instead of rendering the stub zeros as real
/// numbers.
class ServiceAnalyticsBloc
    extends Bloc<ServiceAnalyticsEvent, ServiceAnalyticsState> {
  ServiceAnalyticsBloc({
    required GetProviderServicesOverviewUseCase
    getProviderServicesOverviewUseCase,
  }) : _getProviderServicesOverviewUseCase = getProviderServicesOverviewUseCase,
       super(const ServiceAnalyticsState()) {
    on<ServiceAnalyticsFetchEvent>(_onFetch);
  }

  final GetProviderServicesOverviewUseCase _getProviderServicesOverviewUseCase;

  Future<void> _onFetch(
    ServiceAnalyticsFetchEvent event,
    Emitter<ServiceAnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    final result = await _getProviderServicesOverviewUseCase(
      const NoParams(),
    ).run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (overview) => emit(
        ServiceAnalyticsState(
          status: RequestStatus.success,
          overview: overview,
        ),
      ),
    );
  }
}
