import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organization_settings/src/domain/entities/provider_overview_entity.dart';
import 'package:organization_settings/src/domain/usecases/get_provider_overview_usecase.dart';

part 'provider_overview_event.dart';
part 'provider_overview_state.dart';

/// Owns the KPI-hub summary counts (branches/team/invitations) shown on
/// the organization settings KPI hub — `GET service-provider/overview`.
class ProviderOverviewBloc
    extends Bloc<ProviderOverviewEvent, ProviderOverviewState> {
  ProviderOverviewBloc({required GetProviderOverviewUseCase getOverview})
    : _getOverview = getOverview,
      super(const ProviderOverviewState()) {
    on<ProviderOverviewLoaded>(_onLoaded);
    on<ProviderOverviewRefreshed>(_onLoaded);
  }

  final GetProviderOverviewUseCase _getOverview;

  Future<void> _onLoaded(
    ProviderOverviewEvent event,
    Emitter<ProviderOverviewState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final result = await _getOverview(const NoParams()).run();

    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (overview) => emit(
        state.copyWith(status: RequestStatus.success, overview: overview),
      ),
    );
  }
}
