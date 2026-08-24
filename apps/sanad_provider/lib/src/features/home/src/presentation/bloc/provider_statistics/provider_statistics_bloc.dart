import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';
import 'package:sanad_provider/src/features/home/src/domain/usecases/get_provider_statistics_usecase.dart';

part 'provider_statistics_event.dart';
part 'provider_statistics_state.dart';

/// Owns the dashboard statistic cards shown on the provider home page —
/// `GET service-provider/statistics`.
class ProviderStatisticsBloc
    extends Bloc<ProviderStatisticsEvent, ProviderStatisticsState> {
  ProviderStatisticsBloc({
    required GetProviderStatisticsUseCase getStatistics,
  }) : _getStatistics = getStatistics,
       super(const ProviderStatisticsState()) {
    on<ProviderStatisticsLoaded>(_onLoaded);
    on<ProviderStatisticsRefreshed>(_onLoaded);
  }

  final GetProviderStatisticsUseCase _getStatistics;

  Future<void> _onLoaded(
    ProviderStatisticsEvent event,
    Emitter<ProviderStatisticsState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final result = await _getStatistics(const NoParams()).run();

    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (statistics) => emit(
        state.copyWith(status: RequestStatus.success, statistics: statistics),
      ),
    );
  }
}
