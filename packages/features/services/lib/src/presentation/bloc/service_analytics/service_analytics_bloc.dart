import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/service_analytics_entity.dart';
import 'package:services/src/domain/usecases/get_service_analytics_usecase.dart';

part 'service_analytics_event.dart';
part 'service_analytics_state.dart';

/// Loads `GET /services/analytics` for the dashboard KPI cards.
///
/// The live backend always returns `dataAvailable: false` today (the
/// booking entity does not exist yet) — the state exposes that flag as-is so
/// the presentation layer can show a "not available yet" placeholder instead
/// of rendering the zeroed metrics as real numbers.
class ServiceAnalyticsBloc
    extends Bloc<ServiceAnalyticsEvent, ServiceAnalyticsState> {
  ServiceAnalyticsBloc({
    required GetServiceAnalyticsUseCase getServiceAnalyticsUseCase,
  }) : _getServiceAnalyticsUseCase = getServiceAnalyticsUseCase,
       super(const ServiceAnalyticsState()) {
    on<ServiceAnalyticsFetchEvent>(_onFetch);
  }

  final GetServiceAnalyticsUseCase _getServiceAnalyticsUseCase;

  Future<void> _onFetch(
    ServiceAnalyticsFetchEvent event,
    Emitter<ServiceAnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    final result = await _getServiceAnalyticsUseCase(const NoParams()).run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (analytics) => emit(
        ServiceAnalyticsState(
          status: RequestStatus.success,
          analytics: analytics,
        ),
      ),
    );
  }
}
