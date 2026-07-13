---
name: api
description: Build an API endpoint — endpoint class, DTO, data source, repository, DI
---

# API Skill

Create an API endpoint following Sanad networking conventions.

## Step 1 — Endpoint Class

```dart
abstract final class FeatureEndpoints {
  static const String list = 'features';
  static const String detail = 'features/{id}';
  static String byId(String id) => 'features/$id';
}
```

## Step 2 — DTO Model

```dart
class FeatureDto {
  const FeatureDto({required this.id, required this.name});
  final String id;
  final String name;

  factory FeatureDto.fromJson(Map<String, dynamic> json) => FeatureDto(
    id: json['id'] as String,
    name: json['name'] as String,
  );

  Entity toEntity() => Entity(id: id, name: name);
}
```

## Step 3 — Data Source

```dart
class FeatureRemoteDataSourceImpl implements FeatureRemoteDataSource {
  FeatureRemoteDataSourceImpl(this._client);
  final ApiClientImpl _client;

  @override
  TaskEither<Failure, List<FeatureDto>> fetchAll() =>
    _client.get<List<dynamic>>(FeatureEndpoints.list).map(
      (response) => (response as List).map((e) => FeatureDto.fromJson(e)).toList(),
    );
}
```

## Step 4 — Wire to Repository

See `repository.skill.md` for repository implementation.

## Rules

- Use `authDio` instance (via `ApiClientImpl`) — not `rawDio`
- Return `TaskEither<Failure, T>` throughout
- Map errors via `ErrorMapper` — never expose `DioException`
- Wrap in `NetworkGuard.execute()` for connectivity
