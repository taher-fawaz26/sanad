import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:text_optimization/src/domain/repositories/text_optimization_repository.dart';

class OptimizeTextParams extends Equatable {
  const OptimizeTextParams(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Sends [OptimizeTextParams.text] to the shared AI text-optimization
/// service and returns the optimized replacement text.
class OptimizeTextUseCase implements UseCase<String, OptimizeTextParams> {
  const OptimizeTextUseCase(this._repository);

  final TextOptimizationRepository _repository;

  @override
  TaskEither<Failure, String> call(OptimizeTextParams params) =>
      _repository.optimize(params.text);
}
