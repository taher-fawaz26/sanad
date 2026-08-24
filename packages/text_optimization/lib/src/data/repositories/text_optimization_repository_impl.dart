import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:text_optimization/src/data/datasources/text_optimization_remote_datasource.dart';
import 'package:text_optimization/src/domain/repositories/text_optimization_repository.dart';

class TextOptimizationRepositoryImpl implements TextOptimizationRepository {
  const TextOptimizationRepositoryImpl(this._remoteDataSource);

  final TextOptimizationRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, String> optimize(String text) =>
      _remoteDataSource.optimize(text);
}
