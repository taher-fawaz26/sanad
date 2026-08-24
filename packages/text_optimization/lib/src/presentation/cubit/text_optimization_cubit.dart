import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:text_optimization/src/domain/usecases/optimize_text_usecase.dart';

/// State for one "Enhance with AI" affordance.
///
/// One instance is scoped to a single description field — screens with more
/// than one AI-enhance field provide one [TextOptimizationCubit] per field.
class TextOptimizationState extends Equatable {
  const TextOptimizationState({
    this.status = RequestStatus.initial,
    this.optimizedText,
    this.failure,
  });

  final RequestStatus status;

  /// The most recently returned optimized text — consumed once by the
  /// listening widget (which then calls [TextOptimizationCubit.acknowledge]),
  /// so a rebuild never re-applies a stale value onto the field.
  final String? optimizedText;
  final Failure? failure;

  bool get isLoading => status == RequestStatus.loading;

  TextOptimizationState copyWith({
    RequestStatus? status,
    String? optimizedText,
    Failure? failure,
    bool clearOptimizedText = false,
    bool clearFailure = false,
  }) => TextOptimizationState(
    status: status ?? this.status,
    optimizedText: clearOptimizedText
        ? null
        : (optimizedText ?? this.optimizedText),
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [status, optimizedText, failure];
}

/// Drives one "Enhance with AI" button end to end: validates the input,
/// calls [OptimizeTextUseCase], and always lands on a terminal
/// success/failure state — never leaves [TextOptimizationState.isLoading]
/// stuck `true`.
class TextOptimizationCubit extends Cubit<TextOptimizationState> {
  TextOptimizationCubit(this._useCase) : super(const TextOptimizationState());

  final OptimizeTextUseCase _useCase;

  Future<void> optimize(String text) async {
    // Duplicate-tap guard — mirrors the bloc `droppable()` idiom without a
    // stream transformer, since a Cubit has no event queue to drop from.
    if (state.isLoading) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          clearOptimizedText: true,
          failure: const ValidationFailure(
            message: 'common.enhance_with_ai_empty_input_error',
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final result = await _useCase(OptimizeTextParams(trimmed)).run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (optimizedText) {
        if (optimizedText.trim().isEmpty) {
          emit(
            state.copyWith(
              status: RequestStatus.failure,
              clearOptimizedText: true,
              failure: const ValidationFailure(
                message: 'common.enhance_with_ai_empty_result_error',
              ),
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: RequestStatus.success,
            optimizedText: optimizedText,
          ),
        );
      },
    );
  }

  /// Clears a consumed success/failure back to [RequestStatus.initial] so a
  /// rebuild never re-applies the same [TextOptimizationState.optimizedText]
  /// or re-shows the same failure.
  void acknowledge() {
    if (state.status == RequestStatus.initial) return;
    emit(const TextOptimizationState());
  }
}
