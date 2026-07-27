/// Coarse-grained request lifecycle used by BLoC/Cubit states across the
/// codebase. Every feature state that owns an async operation should carry
/// this alongside the payload (or nullable failure).
///
/// Callers should prefer this over ad-hoc `isLoading` bools + separate error
/// flags — `switch` on the enum keeps UI branches exhaustive.
enum RequestStatus { initial, loading, success, failure }
