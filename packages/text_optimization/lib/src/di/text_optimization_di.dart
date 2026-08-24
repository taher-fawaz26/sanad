import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:text_optimization/src/data/datasources/text_optimization_remote_datasource.dart';
import 'package:text_optimization/src/data/repositories/text_optimization_repository_impl.dart';
import 'package:text_optimization/src/domain/repositories/text_optimization_repository.dart';
import 'package:text_optimization/src/domain/usecases/optimize_text_usecase.dart';
import 'package:text_optimization/src/presentation/cubit/text_optimization_cubit.dart';

/// Dependency registration for the shared "Enhance with AI" flow.
///
/// Registers exactly one [TextOptimizationRepository] for the whole app;
/// every screen's AI-enhance button gets its own [TextOptimizationCubit]
/// instance (factory) built on top of it.
abstract final class TextOptimizationDI {
  TextOptimizationDI._();

  static void init() {
    sl
      ..registerLazySingleton<TextOptimizationRemoteDataSource>(
        () => TextOptimizationRemoteDataSourceImpl(
          sl<BaseApiClient>(
            instanceName: NetworkDI.textOptimizationApiClientInstanceName,
          ),
        ),
      )
      ..registerLazySingleton<TextOptimizationRepository>(
        () => TextOptimizationRepositoryImpl(
          sl<TextOptimizationRemoteDataSource>(),
        ),
      )
      ..registerLazySingleton(
        () => OptimizeTextUseCase(sl<TextOptimizationRepository>()),
      )
      ..registerFactory(() => TextOptimizationCubit(sl<OptimizeTextUseCase>()));
  }
}
