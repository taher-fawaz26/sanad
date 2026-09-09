import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_client/src/features/client_requests/src/data/datasources/catalogue_remote_data_source.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/catalogue_entities.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/catalogue_repository.dart';

/// Maps catalogue DTOs to domain entities.
class CatalogueRepositoryImpl implements CatalogueRepository {
  /// Creates the repository.
  const CatalogueRepositoryImpl(this._remote);

  final CatalogueRemoteDataSource _remote;

  @override
  TaskEither<Failure, Page<CatalogueService>> services(CatalogueQuery query) =>
      _remote
          .services(query)
          .map((page) => page.mapItems((dto) => dto.toEntity()));

  @override
  TaskEither<Failure, Page<CatalogueCategory>> categories(
    CatalogueQuery query,
  ) => _remote
      .categories(query)
      .map((page) => page.mapItems((dto) => dto.toEntity()));
}
