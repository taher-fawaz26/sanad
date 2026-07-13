/// sand_shared_blocs — backwards-compatibility re-export facade.
///
/// All types have been promoted to their canonical packages.
/// Import those directly in new code; this package exists only for
/// backwards-compatible consumers that still reference it.
///
///   ThemeBloc / AppThemeMode  → sand_design_system
///   BaseRequestBloc / State   → sand_core
///   AuthStatus / Notifier     → sand_auth
library shared_blocs;

// ── Theme (canonical: sand_design_system) ──────────────────────────────────
export 'package:design_system/design_system.dart'
    show
        AppThemeMode,
        DarkThemeEvent,
        LightThemeEvent,
        SystemThemeEvent,
        ThemeBloc,
        ThemeEvent,
        ThemeState;

// ── Request BLoC (canonical: sand_core) ────────────────────────────────────
export 'package:core/core.dart'
    show
        BaseRequestBloc,
        BaseRequestEvent,
        BaseRequestState,
        FetchEvent,
        RefreshEvent,
        RequestStatus,
        RetryEvent;

// ── Auth status (canonical: sand_auth) ─────────────────────────────────────
export 'package:auth/auth.dart'
    show AuthStatus, AuthStatusNotifier, RegistrationStatus;
