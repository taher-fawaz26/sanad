# API Guide

Complete API architecture standards for every data layer in the Sanad platform.

---

## Base URLs

Selected via `--dart-define=ENV=<env>` at build time. Default: `dev`.

| Environment | Base URL |
|-------------|----------|
| dev | `https://dev-api.trysanad.us/api/v1/` |
| qa | `https://qa-api.trysanad.us/api/v1/` |
| stage | `https://stage-api.trysanad.us/api/v1/` |
| prod | `https://api.trysanad.us/api/v1/` |

Refresh endpoint: `auth/refresh`  
Default timeouts: 15s connect/receive/send

---

## Dio Instances

| Instance | GetIt Name | Purpose |
|----------|-----------|---------|
| Authenticated | `'authDio'` | All feature API calls |
| Raw | `'rawDio'` | Token refresh only |

## Interceptor Chain (authDio)

```
AcceptLanguage → Auth → RetryOnTimeout → TimeoutError → Logging
```

| Interceptor | Role |
|-------------|------|
| `AcceptLanguageInterceptor` | Sends `Accept-Language` from `TranslateBloc` |
| `AuthInterceptor` | Bearer token injection, 401 refresh with queue |
| `RetryOnTimeoutInterceptor` | Retries on timeout |
| `TimeoutErrorInterceptor` | Normalizes timeout errors |
| `LoggingInterceptor` | Request/response logging (disabled in release) |

---

## Naming Standards

| Artifact | Convention | Example |
|----------|-----------|---------|
| API paths class | `<Feature>ApiPaths` | `OrdersApiPaths` |
| Remote data source (abstract) | `<Feature>RemoteDataSource` | `OrdersRemoteDataSource` |
| Remote data source (impl) | `<Feature>RemoteDataSourceImpl` | `OrdersRemoteDataSourceImpl` |
| Request DTO | `<Action><Feature>Request` | `CreateOrderRequest` |
| Response DTO | `<Feature>Response` | `OrderResponse` |
| Paginated response | `PaginatedResponse<T>` | `PaginatedResponse<OrderResponse>` |
| Cursor response | `CursorResponse<T>` | `CursorResponse<OrderResponse>` |
| Error DTO | `ApiErrorResponse` (shared, in `network`) | — |

---

## Standard Response Model Pattern

```dart
class OrderResponse {
  const OrderResponse({required this.id, required this.status});

  factory OrderResponse.fromJson(Map<String, dynamic> json) => OrderResponse(
        id: json['id'] as String,
        status: json['status'] as String,
      );

  final String id;
  final String status;

  OrderEntity toEntity() => OrderEntity(
        id: id,
        status: OrderStatus.values.byName(status),
      );
}
```

**Rules:**
- Every response model has `fromJson` factory + `toEntity()` method
- Every request model has `toJson()` → `Map<String, dynamic>`
- No `json_serializable` / `freezed` — manual serialization only

---

## Pagination

### Offset Pagination

Use `PaginatedResponse<T>` from `packages/network`:

```dart
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) => PaginatedResponse(
        items: (json['items'] as List<dynamic>)
            .map((e) => itemParser(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['page_size'] as int,
      );

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < total;
}
```

### Cursor Pagination

Use `CursorResponse<T>` from `packages/network`:

```dart
class CursorResponse<T> {
  const CursorResponse({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  factory CursorResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) => CursorResponse(
        items: (json['items'] as List<dynamic>)
            .map((e) => itemParser(e as Map<String, dynamic>))
            .toList(),
        nextCursor: json['next_cursor'] as String?,
        hasMore: json['has_more'] as bool? ?? false,
      );

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}
```

---

## Error Mapping

All errors map through `FailureMapper` in `packages/network` (alias of `ErrorMapper`):

| HTTP / Exception | Failure type |
|------------------|-------------|
| `400` | `ValidationFailure` |
| `401` | `UnauthorizedFailure` |
| `403` | `UnauthorizedRoleFailure` / `UnverifiedUserFailure` |
| `404` | `ServerFailure` (code: `404`) |
| `422` | `ValidationFailure` (with field metadata) |
| `5xx` | `ServerFailure` |
| Connection timeout | `TimeoutFailure` |
| No connectivity | `NoInternetFailure` |
| TLS / certificate | `SecureConnectionFailure` |
| Unknown | `UnknownFailure` |

**Rules:**
- `DioException` never leaks past the data layer
- Data sources use `BaseApiClient.request()` — never raw `Dio`
- Repositories wrap datasource calls; UseCases never import `dio`

```dart
// Repository impl pattern
@override
TaskEither<Failure, OrderEntity> fetchOrder(String id) =>
    _remote.fetchOrder(id).map((r) => r.toEntity());
```

---

## Result Pattern

No custom `Result<T>`. Uses `TaskEither<Failure, T>` from fpdart:

```dart
// Data source
TaskEither<Failure, OrderResponse> fetchOrder(String id);

// Use case
TaskEither<Failure, OrderEntity> call(FetchOrderParams params);

// BLoC
final result = await useCase(params).run();
result.fold(
  (failure) => emit(OrdersFailureState(failure)),
  (order) => emit(OrdersSuccessState(order)),
);
```

---

## Connectivity

Wrap repository calls in `NetworkGuard.execute()` to check connectivity before API calls.

---

## Error Messages

Presentation resolves i18n keys via `ErrorMessages` constants:
- `ErrorMessages.noInternet` → `'errors.no_internet'`
- `ErrorMessages.timeout` → `'errors.timeout'`

Never display raw `Failure.message` to users without i18n resolution.

---

## Data Source Pattern

```dart
abstract class OrdersRemoteDataSource {
  TaskEither<Failure, PaginatedResponse<OrderResponse>> fetchOrders({
    required int page,
    required int pageSize,
  });
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  const OrdersRemoteDataSourceImpl(this._apiClient);
  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, PaginatedResponse<OrderResponse>> fetchOrders({
    required int page,
    required int pageSize,
  }) =>
      _apiClient.request(
        path: OrdersApiPaths.list,
        method: RequestMethod.get,
        query: {'page': page, 'page_size': pageSize},
        parser: (data) => PaginatedResponse.fromJson(
          data as Map<String, dynamic>,
          OrderResponse.fromJson,
        ),
      );
}
```

---

## Validation

Import scanner (`melos validate:arch`) detects `DioException` imports outside `packages/network`.
