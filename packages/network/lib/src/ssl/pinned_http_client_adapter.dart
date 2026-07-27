import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:network/src/ssl/certificate_pinner.dart';
import 'package:network/src/ssl/secure_transport_exceptions.dart';

/// Builds a Dio [HttpClientAdapter] that enforces certificate pinning via
/// [CertificatePinner].
///
/// On IO platforms, this returns an [IOHttpClientAdapter] whose underlying
/// [HttpClient] validates the leaf cert against the pin set on every request.
/// A mismatch — or a pinned host with no configured pins — throws
/// [TlsPinningRejectedException] via Dio, which the shared
/// `error_mapper` already routes to `SecureConnectionFailure`.
///
/// On the web platform (where dart:io HttpClient is unavailable), pinning is
/// a no-op — TLS is handled by the browser. Callers should note that browser
/// deployments cannot pin.
///
/// **Fail-closed semantics:**
/// * `pinner.enforce == false` → validator always accepts (dev/debug).
/// * `pinner.enforce == true` and no pin configured for the host →
///   validator rejects. This is the safe default when a build ships without
///   pins by accident.
HttpClientAdapter buildPinnedHttpClientAdapter(CertificatePinner pinner) {
  final adapter = IOHttpClientAdapter()
    ..validateCertificate = (cert, host, port) {
      if (cert == null) return !pinner.enforce;
      return pinner.check(cert, host);
    };
  return adapter;
}

/// Wraps [buildPinnedHttpClientAdapter] and installs the result on [dio].
/// Convenience for DI wiring.
void installPinnedAdapter(Dio dio, CertificatePinner pinner) {
  dio.httpClientAdapter = buildPinnedHttpClientAdapter(pinner);
}

/// Convenience factory: build a [CertificatePinner] from a `--dart-define`
/// pin string of the form `host1=pinA,pinB;host2=pinC`. Whitespace and empty
/// entries are ignored. Passing an empty string returns a disabled pinner
/// in [debug]; in release the caller should treat empty pins as fail-closed.
CertificatePinner parsePinnerSpec(String spec, {required bool enforce}) {
  if (spec.trim().isEmpty) {
    return CertificatePinner(pinsByHost: const {}, enforce: enforce);
  }
  final map = <String, Set<String>>{};
  for (final entry in spec.split(';')) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) continue;
    final eq = trimmed.indexOf('=');
    if (eq <= 0) {
      throw ArgumentError.value(
        entry,
        'spec',
        'expected host=pin[,pin...] but got "$entry"',
      );
    }
    final host = trimmed.substring(0, eq).trim().toLowerCase();
    final pins = trimmed
        .substring(eq + 1)
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet();
    map[host] = pins;
  }
  return CertificatePinner(pinsByHost: map, enforce: enforce);
}

/// Sentinel exception exported for callers that want to construct a rejection
/// synchronously (e.g. in tests). The runtime path uses Dio's own error
/// wrapping when [buildPinnedHttpClientAdapter]'s validator returns false.
const TlsPinningRejectedException kPinRejectedSentinel =
    TlsPinningRejectedException('certificate not in pin set');

/// Builds a [CertificatePinner] from the `--dart-define=TLS_PINS=...` build
/// value. The spec format is described on [parsePinnerSpec].
///
/// Enforcement defaults to `!kDebugMode` (release/profile builds enforce;
/// debug builds skip pinning so local dev servers work). Callers can override
/// via [enforce].
///
/// **Fail-closed behavior:** if the build ships without a `TLS_PINS`
/// define, the returned pinner has an empty [CertificatePinner.pinsByHost]
/// but `enforce: true` in release, so every TLS connection is rejected until
/// pins are supplied. This is intentional — a release build without pins
/// should not silently downgrade to unpinned TLS.
CertificatePinner pinnerFromEnvironment({bool? enforce}) {
  const spec = String.fromEnvironment('TLS_PINS');
  return parsePinnerSpec(spec, enforce: enforce ?? !kDebugMode);
}
