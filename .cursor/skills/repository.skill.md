---
name: repository
description: Create a repository — abstract contract, implementation, fake, DI registration
---

# Repository Skill

Create a repository following Sanad clean architecture.

## Step 1 — Domain Contract

```dart
// packages/features/<feature>/lib/src/domain/repositories/feature_repository.dart
abstract interface class FeatureRepository {
  TaskEither<Failure, List<Entity>> getAll();
  TaskEither<Failure, Entity> getById(String id);
  TaskEither<Failure, void> create(CreateParams params);
}
```

## Step 2 — Data Source

```dart
// packages/features/<feature>/lib/src/data/datasources/feature_remote_data_source.dart
abstract interface class FeatureRemoteDataSource {
  TaskEither<Failure, List<FeatureDto>> fetchAll();
}

class FeatureRemoteDataSourceImpl implements FeatureRemoteDataSource {
  final ApiClientImpl _client;
  // Use _client.get/post with endpoint paths
}
```

## Step 3 — Repository Implementation

```dart
// packages/features/<feature>/lib/src/data/repositories/feature_repository_impl.dart
class FeatureRepositoryImpl implements FeatureRepository {
  FeatureRepositoryImpl(this._dataSource);
  final FeatureRemoteDataSource _dataSource;

  @override
  TaskEither<Failure, List<Entity>> getAll() =>
    _dataSource.fetchAll().map((dtos) => dtos.map((d) => d.toEntity()).toList());
}
```

## Step 4 — Fake for Testing

```dart
// packages/testing/lib/src/fakes/fake_feature_repository.dart
class FakeFeatureRepository implements FeatureRepository {
  TaskEither<Failure, List<Entity>> result = TaskEither.right([]);
  @override
  TaskEither<Failure, List<Entity>> getAll() => result;
}
```

## Step 5 — DI Registration

```dart
sl.registerLazySingleton<FeatureRemoteDataSource>(FeatureRemoteDataSourceImpl.new);
sl.registerLazySingleton<FeatureRepository>(FeatureRepositoryImpl.new);
```

## Rules

- Return `TaskEither<Failure, T>` — never `Future<T>`
- Wrap calls in `NetworkGuard.execute()` for connectivity check
- DTOs in `data/models/`, entities in `domain/entities/`
- Never expose `DioException` — map via `ErrorMapper`
