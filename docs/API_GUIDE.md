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

All errors map through `ErrorMapper.mapError` in `packages/network`, invoked once in
`ApiClientImpl.request`. (`FailureMapper` is a legacy alias with no call sites.) The mapping
below reflects the implementation after Epic 1 — see `docs/ARCHITECTURE_BLUEPRINT.md` §2/§6/§16.

| HTTP / Exception | Failure type |
|------------------|-------------|
| `400` (`message` is an array) / `422` | `ValidationFailure` (**all** messages; optional `fieldErrors`) |
| `400` (single-string message) | `BusinessRuleFailure` (e.g. "Cannot delete the only branch") |
| `401` | `UnauthorizedFailure` |
| `403` | `UnverifiedUserFailure` / `UnauthorizedRoleFailure` (prose-sniffed until backend error codes exist) |
| `404` | `ServerFailure` (code: `404`) |
| `409` | `ConflictFailure` |
| `429` | `RateLimitFailure` |
| `5xx` | `ServerFailure` |
| Connection/receive/send timeout | `TimeoutFailure` |
| No connectivity / connection error | `NoInternetFailure` |
| Cancelled request | `NetworkFailure` |
| TLS / certificate | `SecureConnectionFailure` |
| Unknown | `UnknownFailure` |

`Failure.isRetryable` (in `core`) classifies which of these are worth retrying (transient
transport, 5xx, 429) vs not (validation, auth, permission, conflict, business-rule, 4xx).

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

Apps also register `ConnectivityController` + wrap the root with `ConnectivityOfflineBinder` to push `/offline` (`AppNetworkErrorPage`) when the device goes offline. The route is **pushed** (not replaced) so Back pops to the previous screen; the screen can be shown again on the next offline transition or via `context.push('/offline')`. Retry calls `ConnectivityController.check()` and pops when online.

---

## Error Messages

Presentation resolves a `Failure` to a localized string via the **`FailureLocalizer`**
extension (`package:localization`) — the single resolver:

```dart
showAppErrorSnackbar(context: context, title: failure.localizedMessage());
// full-area error state:
final display = failureErrorDisplay(failure); // title/description/isConnectivity/isRetryable
```

`localizedMessage()` translates dotted i18n keys (`errors.*`, `auth.*`) and passes
backend prose through (the backend localizes its own messages via the Accept-Language
interceptor). `errorKey` gives a type-based key for telemetry/fallback. Do **not** re-introduce
the old `message.contains(' ') ? raw : message.tr()` heuristic — it was removed in Epic 1.

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

## Media upload (`POST media/onboarding`)

Used by registration (Emirates ID, trade licence) during onboarding.

| Item | Detail |
|------|--------|
| Path | `media/onboarding` (`MediaApiPaths.onboarding`) |
| Method | `POST` multipart (`field: file`) |
| Client | `SecureDioClient.postMultipart` |
| Auth | Onboarding Bearer via explicit `Authorization` header (not session `TokenManager`) |
| Progress | Dio `onSendProgress` |
| Cancel | Dio `CancelToken` keyed by document slot |
| Response | `{ id, originalName, fileName, mimeType, size, type, url, createdAt }` |

Package: `packages/features/registration` (`UploadSingleMediaUseCase`).

---

## Account settings (`GET/PATCH account-settings`)

Signed-in provider account profile (name, email, phone, preferred language).

| Item | Detail |
|------|--------|
| Path | `account-settings` (`AccountSettingsApiPaths.accountSettings`) |
| Methods | `GET` — fetch settings; `PATCH` — partial update |
| PATCH body | `{ "name"?: string, "preferredLanguage"?: "en" \| "ar" }` |
| Response | `{ id, name, email, phone, preferredLanguage }` |

Package: `packages/features/account_settings` (`GetAccountSettingsUseCase`, `UpdateAccountSettingsUseCase`).

---

## Client requests (`/requests`)

The client-owned service-request lifecycle. Full contract, nullability rules and
the structured 409 handling: [`features/client-requests.md`](features/client-requests.md).

| Method | Path | Notes |
|--------|------|-------|
| `GET` | `requests` | Own requests only; optional `status`; `limit` capped at 100 |
| `POST` | `requests` | Creates a `DRAFT`. Every field optional — completeness is enforced at submit |
| `GET` / `PATCH` | `requests/:id` | `PATCH` answers `409` once an offer awaits a reply |
| `POST` | `requests/:id/submit` | Structured `409`: `NO_PROVIDERS_FOR_SERVICE`, `NO_COVERAGE`, `OUTSIDE_HOURS` |
| `POST` | `requests/:id/{cancel,confirm,dispute}` | Cancel and dispute need a 3–1000 char `reason` |
| `POST` | `requests/:id/offers/:offerId/{accept,reject,counter}` | `offerId` must belong to `:id`; a mismatch is `404` |

## Provider request workspace (`/provider/requests`)

The provider-side view of the same requests, in a **different, privacy-gated
payload**. Details: [`features/provider-requests.md`](features/provider-requests.md).

| Method | Path | Notes |
|--------|------|-------|
| `GET` | `provider/requests` | `tab`, `search`, `branchId`; **`tab` is server-derived and canonical** |
| `GET` | `provider/requests/{counts,stats}` | Badge counts per tab; four headline numbers |
| `GET` | `provider/requests/:id` | `contact.unlocked` is the only signal for contact visibility |
| `POST` | `provider/requests/:id/offers` | Matched branch + future `proposedAt`; `409` when re-bids are exhausted |
| `POST` | `provider/requests/:id/{complete,cancel}` | Cancel needs a `reason` |
| `POST` | `provider/offers/:offerId/{withdraw,accept,decline,counter}` | Withdraw **consumes a re-bid** |

## Notifications and push (`/notifications`)

See [`features/notifications.md`](features/notifications.md).

| Method | Path | Notes |
|--------|------|-------|
| `GET` | `notifications` | Rows carry nullable `subjectType`, `subjectId`, `metadata` |
| `PATCH` | `notifications/:id/read`, `notifications/read-all` | |
| `POST` | `notifications/devices` | `204`. An **upsert** — sent on login, every launch, and every token rotation |
| `DELETE` | `notifications/devices/:token` | `204`, idempotent. Sent **before** the session is cleared |

> **`notifications/stream` and `notifications/stream-ticket` are web-only.** The
> SSE stream is not implemented in either mobile app. FCM covers background
> delivery, and screens re-read their resource when they become active.

---

## Pagination

Every paginated endpoint answers `{ data: [...], meta: { totalItems, itemCount,
itemsPerPage, totalPages, currentPage } }`, parsed by `parsePage` into
`Page<T>`.

**`limit` is capped at 100.** Sending 101 or more answers `400`. `PageQuery`
clamps it centrally in `toQueryMap()` (`kMaxPageLimit`), so no individual screen
has to remember, and an over-large caller degrades to the maximum instead of
failing the request.

---

## Validation

Import scanner (`melos validate:arch`) detects `DioException` imports outside `packages/network`.
