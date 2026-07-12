---
name: feature
description: Create a complete feature package — domain, data, presentation, DI, routes, localization, tests
---

# Feature Skill

Create a new feature package following Sanad clean architecture.

## Step 1 — Scaffold Package

```
packages/<name>/
  lib/
    <name>.dart          # barrel
    src/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        bloc/
        pages/
        widgets/
      di/
        <name>_di.dart
      routes/
        <name>_routes.dart
  test/
  pubspec.yaml
  analysis_options.yaml
```

## Step 2 — Register in Workspace

1. Add to root `pubspec.yaml` workspace list
2. Add to `melos.yaml` packages list
3. Run `melos bootstrap`

## Step 3 — Domain Layer

```dart
// Repository contract
abstract interface class FeatureRepository {
  TaskEither<Failure, Entity> getData(Params params);
}

// Use case
class GetDataUseCase implements UseCase<Entity, Params> {
  final FeatureRepository _repo;
  @override
  TaskEither<Failure, Entity> call(Params params) => _repo.getData(params);
}
```

## Step 4 — Data Layer

```dart
class FeatureRepositoryImpl implements FeatureRepository {
  final FeatureDataSource _dataSource;
  @override
  TaskEither<Failure, Entity> getData(Params params) =>
    _dataSource.fetch(params).map((dto) => dto.toEntity());
}
```

## Step 5 — Presentation

- BLoC with events/states
- Pages using DS components
- No business logic in widgets

## Step 6 — DI

```dart
abstract final class FeatureDI {
  static void init() {
    sl.registerLazySingleton<FeatureRepository>(FeatureRepositoryImpl.new);
    sl.registerLazySingleton(() => GetDataUseCase(sl()));
    sl.registerFactory(() => FeatureBloc(sl()));
  }
}
```

## Step 7 — Routes

```dart
abstract final class FeatureRoutes {
  static const String list = '/feature';
  static const String detail = '/feature/:id';
}
```

## Step 8 — Localization

Add keys to both `ar-AR.json` and `en-US.json`.

## Step 9 — Tests

- Use case unit test with `FakeRepository`
- BLoC test with `bloc_test`
- Repository test with `TaskEither.run()`

## Step 10 — Documentation

Update `docs/FEATURE_GUIDE.md` and `docs/PACKAGE_GUIDE.md`.
