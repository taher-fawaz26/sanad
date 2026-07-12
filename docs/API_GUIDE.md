# API Guide

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

## Error Types

Sealed `Failure` hierarchy in `packages/core`:

| Failure | When |
|---------|------|
| `NetworkFailure` | General network error |
| `ServerFailure` | 5xx responses |
| `TimeoutFailure` | Request timeout |
| `UnauthorizedFailure` | 401 after refresh fails |
| `NoInternetFailure` | No connectivity |

Mapped via `ErrorMapper.mapError()` — `DioException` never leaks past data layer.

## Result Pattern

No custom `Result<T>`. Uses `TaskEither<Failure, T>` from fpdart:

```dart
// Use case
TaskEither<Failure, User> call(LoginParams params);

// BLoC
final result = await useCase(params).run();
result.fold(
  (failure) => emit(LoginFailureState(failure)),
  (user) => emit(LoginSuccessState(user)),
);
```

## Error Messages

Presentation resolves i18n keys via `ErrorMessages` constants:
- `ErrorMessages.noInternet` → `'errors.no_internet'`
- `ErrorMessages.timeout` → `'errors.timeout'`

## Connectivity

Wrap repository calls in `NetworkGuard.execute()` to check connectivity before API calls.
