import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Certificate pin set for TLS pinning.
///
/// Contains a map of host → allowed SHA-256 fingerprints of the DER-encoded
/// leaf certificate (base64). Fingerprints must be lowercase, un-prefixed
/// base64 of the raw 32-byte SHA-256 digest.
///
/// **This is intentionally cert-fingerprint pinning, not public-key pinning.**
/// It's the placeholder implementation for the initial scaffold:
///
/// * ✅ Blocks classic MITM with an untrusted CA that has issued a different
///   cert for the pinned host.
/// * ❌ Requires an app update when the server rotates its cert.
///
/// Follow-up (tracked as a Phase 2 item) is to swap this for SPKI pinning by
/// hashing the leaf's `subjectPublicKeyInfo` bytes instead of the whole cert,
/// which survives cert rotation as long as the key is preserved.
///
/// **Fail-closed contract:** in release builds, when [enforce] is `true` and
/// [pinsByHost] is empty for a pinned host (or the map itself is empty), the
/// adapter MUST refuse every TLS connection. This makes an accidentally-shipped
/// empty-pins configuration fail-safe rather than silently unpinned.
class CertificatePinner {
  const CertificatePinner({
    required this.pinsByHost,
    required this.enforce,
  });

  /// A pinner that never rejects — for tests or debug builds where the
  /// developer machine's local certs would otherwise fail every request.
  const CertificatePinner.disabled()
      : pinsByHost = const {},
        enforce = false;

  /// Host → set of allowed base64 SHA-256 fingerprints of the DER cert.
  ///
  /// Host matching is exact and case-insensitive. Wildcards are not supported;
  /// register each hostname (including staging/prod variants) explicitly.
  final Map<String, Set<String>> pinsByHost;

  /// Whether pinning is actively enforced. When `false`, [check] returns
  /// `true` unconditionally. Callers typically set this to `!kDebugMode` (or
  /// wire it to a build flag) so debug builds can hit local dev servers.
  final bool enforce;

  /// Whether this pinner has at least one host with at least one pin. When
  /// [enforce] is `true` and this is `false`, the adapter should treat all
  /// TLS connections as un-pinnable and fail closed — the safe interpretation
  /// of a misconfiguration.
  bool get hasAnyPin =>
      pinsByHost.values.any((pins) => pins.isNotEmpty);

  /// Verifies [cert] against the pin set for [host]. Returns `true` when
  /// [enforce] is `false`, or the certificate's SHA-256 matches a pin for
  /// the (case-normalized) host. Returns `false` for everything else,
  /// including hosts with no configured pins under [enforce] mode.
  bool check(X509Certificate cert, String host) {
    if (!enforce) return true;
    final normalized = host.toLowerCase();
    final pins = pinsByHost[normalized];
    if (pins == null || pins.isEmpty) return false;
    final fingerprint = fingerprintOf(cert);
    return pins.contains(fingerprint);
  }

  /// Base64-encoded SHA-256 fingerprint of [cert]'s DER encoding.
  static String fingerprintOf(X509Certificate cert) =>
      base64.encode(sha256.convert(cert.der).bytes);
}
