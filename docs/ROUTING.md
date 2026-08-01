# Routing

## Architecture

Each app has its own GoRouter configuration:

| App | Router Builder | Location |
|-----|---------------|----------|
| Client | `buildClientRouter()` | `apps/sanad_client/lib/src/routing/` |
| Provider | `buildProviderRouter()` | `apps/sanad_provider/lib/src/routing/` |

## GoRouter Setup

```dart
GoRouter(
  refreshListenable: sl<AuthStatusNotifier>(),
  redirect: (context, state) {
    final isAuthenticated = sl<AuthStatusNotifier>().status == AuthStatus.authenticated;
    final isProtected = AppRoutes.protected.contains(state.matchedLocation);
    if (isProtected && !isAuthenticated) return AuthRoutes.login;
    return null;
  },
  routes: [ /* feature routes */ ],
)
```

## Route Classes

| Class | Package | Paths |
|-------|---------|-------|
| `AuthRoutes` | `auth` | `/`, `/login`, `/register` |
| `OtpRoutes` | `otp` | `/otp` |
| `ForgotPasswordRoutes` | `forgot_password` | `/forgot-password`, `/forgot-password/reset` |
| `AppRoutes` | `sanad_provider` | `/home`, `/messages`, `/requests`, `/services`, `/settings`, `/branches`, `/branches/add` |

## Auth Guard

- `AuthStatusNotifier` (`ChangeNotifier`) drives `refreshListenable`
- Protected routes declared in `AppRoutes.protected` set
- Redirect to `/login` when unauthenticated
- Never check auth inside widget `build()`

## Shell Navigation (Provider)

Bottom-nav tabs via `StatefulShellRoute.indexedStack`:

| Tab | Path | Page |
|-----|------|------|
| Home | `/home` | `ProviderHomePage` |
| Messages | `/messages` | `ProviderMessagesPage` |
| Requests | `/requests` | `RequestsPage` |
| Services | `/services` | `ProviderServicesPage` |
| Settings | `/settings` | `ProviderSettingsPage` |

Branch order matches [ProviderBottomNavDestination] in
`apps/sanad_provider/lib/src/routing/shell/provider_bottom_nav.dart`.

## Typed Navigation Extras

```dart
// Define args class
class OtpArgs {
  const OtpArgs({required this.phone});
  final String phone;
}

// Navigate with extras
context.push(OtpRoutes.verify, extra: OtpArgs(phone: phone));

// Read in route builder
final args = state.extra as OtpArgs;
```

## Feature Route Registration

Feature packages define route constants. App router assembles them:

```dart
// In provider_router.dart
GoRoute(path: AuthRoutes.login, builder: (_, __) => const LoginPage()),
GoRoute(path: AppRoutes.addBranch, builder: (_, __) => const AddBranchPage()),
```

## Deep Linking

- Route paths must be stable and URL-safe
- Use hyphens, not spaces: `/forgot-password` not `/forgot password`
- No dynamic segments without typed validation

## Navigation API

```dart
context.go('/home');           // Replace current route
context.push('/branches/add'); // Push onto stack
context.pop();                 // Pop current route
```

Never use `Navigator.push()` directly.

## DI in Routes

Inject BLoCs via `BlocProvider` in `GoRoute.builder`:

```dart
GoRoute(
  path: FeatureRoutes.list,
  builder: (context, state) => BlocProvider(
    create: (_) => sl<FeatureBloc>(),
    child: const FeaturePage(),
  ),
),
```
