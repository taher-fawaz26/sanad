# Analytics Events

Document all analytics events logged via `ObservabilityService.logEvent`.

| Event | Params | When |
|-------|--------|------|
| `login_success` | `method` | User authenticates |
| `login_failure` | `reason` | Login fails |
| `page_view` | `screen` | Via `logPageView` / GoRouter observer |
| `feature_flag_checked` | `flag`, `enabled` | Remote config flag read |

## Policy

- Never log tokens, passwords, phone numbers, or email addresses
- Use opaque user IDs only via `setUser`
- DEBUG/INFO logs stay local — see `packages/app_logger`
