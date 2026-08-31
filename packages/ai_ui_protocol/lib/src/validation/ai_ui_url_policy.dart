import 'package:equatable/equatable.dart';

/// Decides whether an AI-supplied URL may be used at all.
///
/// This closes a real gap: `UrlLauncherService.openUrl` in `packages/device`
/// launches whatever `Uri.parse` accepts, with no scheme or host check. An
/// AI-supplied URL must never reach it unfiltered, so the policy runs during
/// *validation* — a blocked URL is stripped from the document and never
/// reaches a widget, let alone a launcher.
///
/// The default policy allows nothing. A host opts in explicitly with the set
/// of origins it trusts.
final class AiUiUrlPolicy extends Equatable {
  const AiUiUrlPolicy({this.allowedHosts = const {}});

  /// Blocks every URL. The correct default for a prototype and for any surface
  /// that has not thought about its allowlist yet.
  static const AiUiUrlPolicy denyAll = AiUiUrlPolicy();

  /// Lowercase hosts. An entry may be an exact host (`cdn.trysanad.us`) or a
  /// dot-prefixed suffix (`.trysanad.us`) matching that domain and its
  /// subdomains.
  final Set<String> allowedHosts;

  bool isAllowed(String raw) => reject(raw) == null;

  /// `null` when the URL is acceptable, otherwise a short, non-sensitive
  /// reason suitable for a diagnostic `detail`.
  ///
  /// The returned string never includes the URL itself — an AI-supplied URL
  /// can carry tracking identifiers, so it is not something to write into
  /// logs.
  String? reject(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return 'unparseable';
    if (uri.scheme.toLowerCase() != 'https') return 'scheme not https';

    // `https://user:pass@evil.example/` — userinfo is a classic way to make a
    // hostile host look like a trusted one to a human reader.
    if (uri.userInfo.isNotEmpty) return 'userinfo present';

    final host = uri.host.toLowerCase();
    if (host.isEmpty) return 'empty host';
    if (!_hostAllowed(host)) return 'host not allowlisted';
    return null;
  }

  bool _hostAllowed(String host) {
    for (final allowed in allowedHosts) {
      final normalized = allowed.toLowerCase();
      if (normalized.startsWith('.')) {
        if (host == normalized.substring(1) || host.endsWith(normalized)) {
          return true;
        }
      } else if (host == normalized) {
        return true;
      }
    }
    return false;
  }

  @override
  List<Object?> get props => [allowedHosts];
}
