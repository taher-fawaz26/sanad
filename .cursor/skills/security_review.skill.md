---
name: security_review
description: Security review — secrets, storage, network, auth, logging, dependencies
---

# Security Review Skill

Review project security posture.

## 1. Secret Scanning

```bash
rg "api[_-]?key|secret|password|token" --glob "*.dart" -i
rg "Bearer " --glob "*.dart"
rg "sk_live|pk_live|AIza" --glob "*"
```

- [ ] No hardcoded API keys, tokens, or passwords
- [ ] No secrets in `packages/config` source
- [ ] Secrets via `--dart-define` only

## 2. Storage Review

```bash
rg "SharedPreferences" --glob "*.dart"
rg "Hive\.box" --glob "*.dart"
```

- [ ] Tokens use `SecureTokenStorage` / `flutter_secure_storage`
- [ ] No sensitive data in `SharedPreferences`
- [ ] No unencrypted Hive for credentials

## 3. Network Security

- [ ] SSL pinning not disabled in `packages/network`
- [ ] No `badCertificateCallback` returning `true`
- [ ] All feature calls use `authDio` (not `rawDio`)
- [ ] 15s timeouts enforced

## 4. Authentication Review

- [ ] `AuthInterceptor` is sole Bearer token injector
- [ ] Token refresh handled in interceptor only
- [ ] 401 triggers refresh, not logout (unless refresh fails)
- [ ] No manual token injection in features

## 5. Logging Review

```bash
rg "print\(" --glob "*.dart"
rg "logger\." --glob "*.dart" | rg -i "token|password|secret"
```

- [ ] No `print()` with sensitive data
- [ ] `LoggingInterceptor` respects `kReleaseMode`
- [ ] No PII in debug logs

## 6. API Security

- [ ] `DioException` never exposed to presentation layer
- [ ] Error messages use i18n keys, not raw server messages
- [ ] `AcceptLanguage` header set by interceptor

## 7. Dependency Vulnerabilities

```bash
dart pub outdated
```

- [ ] No known CVEs in dependencies
- [ ] Firebase/SDK versions up to date

## Output

Risk matrix: **Critical** / **High** / **Medium** / **Low** with remediation steps.
