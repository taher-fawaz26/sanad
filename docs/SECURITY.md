# Security

## Security Architecture

```
Presentation (BLoC) → UseCase → Repository → ApiClientImpl → Dio (authDio)
                                                              ↓
                                                    AuthInterceptor (token injection)
                                                    LoggingInterceptor (no secrets in release)
```

Sensitive data never reaches the presentation layer as raw HTTP errors or tokens.

## Authentication Flow

1. User logs in → `AuthBloc` → `AuthLoginUseCase` → `AuthRepository`
2. Repository stores tokens via `SecureTokenStorage`
3. Subsequent requests: `AuthInterceptor` injects Bearer token
4. 401 response: interceptor attempts token refresh via `rawDio`
5. Refresh failure: logout callback triggered

## Token Handling

| Storage | Use | Package |
|---------|-----|---------|
| Access token | `SecureTokenStorage` | `packages/storage` |
| Refresh token | `SecureTokenStorage` | `packages/storage` |
| Session state | `AuthStatusNotifier` | `packages/auth` |

**Never** store tokens in:
- `SharedPreferences`
- Unencrypted Hive boxes
- Memory beyond the interceptor lifecycle

## Secure Storage

```dart
// packages/storage — flutter_secure_storage wrapper
final storage = sl<SecureTokenStorage>();
await storage.saveAccessToken(token);
final token = await storage.getAccessToken();
```

## Logging Policy

- `LoggingInterceptor` logs request/response metadata only
- **Never** log: tokens, passwords, PII, full request bodies with credentials
- Disable verbose logging in release: check `kReleaseMode`
- No `print()` statements with sensitive data

## API Security

- All feature calls use `authDio` (with auth interceptor)
- Token refresh uses `rawDio` (no auth interceptor — avoids loop)
- `DioException` mapped to `Failure` via `ErrorMapper` — never exposed to UI
- 15s timeouts enforced by default
- `Accept-Language` header set by interceptor (not hardcoded)

## SSL Pinning

Configured in `packages/network`. Do not disable without explicit instruction.
Never use `badCertificateCallback` that returns `true`.

## Secret Management

- API keys and secrets via `--dart-define` at build time only
- No secrets in `packages/config` source code
- No secrets in version control
- Environment-specific values in `packages/flavors`

## OWASP Mobile Top 10 Applicability

| Risk | Mitigation |
|------|-----------|
| M1: Improper credential usage | `SecureTokenStorage`, `AuthInterceptor` |
| M2: Inadequate supply chain | `dependencies` package, `melos bootstrap` |
| M3: Insecure auth/authorization | Bearer + refresh flow, 401 handling |
| M9: Insecure data storage | `flutter_secure_storage`, no SharedPreferences for tokens |
| M10: Insufficient cryptography | SSL pinning, certificate validation |

## Security Review

Use `security_review.skill.md` for structured security audits.
