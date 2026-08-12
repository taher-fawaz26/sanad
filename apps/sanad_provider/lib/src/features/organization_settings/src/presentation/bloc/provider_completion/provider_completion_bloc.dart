import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_provider_completion_usecase.dart';

part 'provider_completion_event.dart';
part 'provider_completion_state.dart';

/// Owns the KPI-hub "Complete your organization setup" card data —
/// `GET service-provider/completion`.
class ProviderCompletionBloc
    extends Bloc<ProviderCompletionEvent, ProviderCompletionState> {
  ProviderCompletionBloc({required GetProviderCompletionUseCase getCompletion})
    : _getCompletion = getCompletion,
      super(const ProviderCompletionState()) {
    on<ProviderCompletionLoaded>(_onLoaded);
    on<ProviderCompletionRefreshed>(_onLoaded);
  }

  final GetProviderCompletionUseCase _getCompletion;

  Future<void> _onLoaded(
    ProviderCompletionEvent event,
    Emitter<ProviderCompletionState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final result = await _getCompletion(const NoParams()).run();

    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (completion) => emit(
        state.copyWith(status: RequestStatus.success, completion: completion),
      ),
    );
  }
}
