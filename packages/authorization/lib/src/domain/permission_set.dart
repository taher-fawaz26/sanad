import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Immutable, parsed view over a user's effective permission strings
/// (`GET /me.permissions`), e.g. `provider:branch:view`.
///
/// Parsing happens once, at construction — [can] is an O(1) exact-set
/// lookup plus a scan of a small wildcard-prefix list, never a re-parse.
///
/// Matching is fail-closed: a blank/unknown action denies, and malformed
/// catalog entries are dropped rather than granted. Matching is
/// case-sensitive by design — the backend is consistently lowercase, and
/// silently lowercasing here would mask a real contract drift (see
/// `provider_rbac_contract_test.dart` for the backend-side pin).
///
/// Wildcard semantics (`provider:*` grants any `provider:`-prefixed action)
/// are an INFERRED contract — the backend has not documented `*` semantics
/// anywhere; the shape was only observed live on provider-owner accounts.
/// See the package README before changing this rule.
@immutable
final class PermissionSet extends Equatable {
  factory PermissionSet.from(Iterable<String> raw) {
    var grantsAll = false;
    final prefixes = <String>{};
    final exact = <String>{};

    for (final entry in raw) {
      final trimmed = entry.trim();
      if (trimmed.isEmpty) {
        _logDropped(entry);
        continue;
      }
      if (trimmed == '*') {
        grantsAll = true;
        continue;
      }
      if (trimmed.endsWith(':*')) {
        // Strip the trailing '*', keep the ':' so a granted prefix can never
        // match a same-prefixed-but-different segment, e.g. 'provider:*'
        // must not match 'providerx:y'.
        prefixes.add(trimmed.substring(0, trimmed.length - 1));
        continue;
      }
      if (trimmed.contains('*')) {
        // A non-terminal wildcard (e.g. 'provider:*:view') has no defined
        // backend semantics. Do not guess — drop it rather than risk an
        // over-broad grant.
        _logDropped(entry);
        continue;
      }
      exact.add(trimmed);
    }

    return PermissionSet._(
      grantsAll: grantsAll,
      prefixes: List.unmodifiable(prefixes),
      exact: Set.unmodifiable(exact),
    );
  }

  const PermissionSet._({
    required bool grantsAll,
    required List<String> prefixes,
    required Set<String> exact,
  }) : _grantsAll = grantsAll,
       _prefixes = prefixes,
       _exact = exact;

  static const PermissionSet empty = PermissionSet._(
    grantsAll: false,
    prefixes: [],
    exact: {},
  );

  final bool _grantsAll;
  final List<String> _prefixes;
  final Set<String> _exact;

  /// `true` iff the set grants [action].
  bool can(String action) {
    if (action.trim().isEmpty) return false;
    if (_grantsAll) return true;
    if (_exact.contains(action)) return true;
    for (final prefix in _prefixes) {
      if (action.startsWith(prefix)) return true;
    }
    return false;
  }

  /// `true` iff any of [actions] is granted.
  bool canAny(Iterable<String> actions) => actions.any(can);

  /// `true` iff every one of [actions] is granted. `true` for an empty
  /// iterable — vacuously satisfied, matching [Iterable.every] semantics.
  bool canAll(Iterable<String> actions) => actions.every(can);

  /// Debug-only diagnostic — wrapped in `assert` (not `kDebugMode`/
  /// `debugPrint`) so this stays pure Dart, matching the class-level "no
  /// Flutter import" contract. Stripped entirely from release builds.
  static void _logDropped(String entry) {
    assert(() {
      // `print` (not a logger) is deliberate: this package stays pure Dart,
      // and the call only ever executes inside `assert`, so it is compiled
      // out of release builds entirely.
      // ignore: avoid_print
      print('[authorization] dropped malformed permission entry: "$entry"');
      return true;
    }(), 'debug-only diagnostic for a dropped permission entry');
  }

  @override
  List<Object?> get props => [_grantsAll, _prefixes, _exact];
}
