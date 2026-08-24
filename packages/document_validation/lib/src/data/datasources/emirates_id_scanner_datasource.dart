import 'dart:io';

import 'package:document_validation/src/domain/policies/emirates_id_signal_policy.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Runs on-device text recognition and scores the result against
/// [EmiratesIdSignalPolicy] — behind the package boundary so nothing else
/// in this repository references `package:google_mlkit_text_recognition`
/// directly.
///
/// `eid_scanner` (the package originally named in the feature spec) was
/// rejected after dependency verification: it pins `camera: 0.10.4` and
/// `google_ml_kit: ^0.19.0` (→ `google_mlkit_text_recognition: ^0.14.0`),
/// both of which conflict with `document_camera_frame` — the scanner
/// already used throughout this app (see this package's README). This
/// datasource achieves the same pre-upload gate using the ML-Kit
/// text-recognition package already resolved in this workspace, at the
/// version `document_camera_frame` itself requires — zero new conflicts.
class EmiratesIdScannerDataSource {
  EmiratesIdScannerDataSource();

  // `TextRecognitionScript.latin` is the plugin's default — explicit here
  // only in the doc comment above, not as a redundant constructor argument.
  final TextRecognizer _recognizer = TextRecognizer();

  /// In-flight recognition calls keyed by file path — a repeated tap on the
  /// same just-captured file reuses the same run rather than invoking the
  /// native recognizer twice concurrently.
  final Map<String, Future<bool?>> _inFlight = {};

  /// Returns `true` when [imagePath] looks like an Emirates ID, `false`
  /// when it confidently does not, or `null` when the recognizer itself
  /// failed to run (unreadable file, ML Kit error) — the caller maps `null`
  /// to a `VALIDATION_ENGINE_ERROR`, distinct from a confident rejection.
  Future<bool?> looksLikeEmiratesId(String imagePath) {
    return _inFlight.putIfAbsent(imagePath, () async {
      try {
        final file = File(imagePath);
        if (!file.existsSync()) return null;

        final inputImage = InputImage.fromFilePath(imagePath);
        final recognized = await _recognizer.processImage(inputImage);
        return EmiratesIdSignalPolicy.evaluate(recognized.text);
      } on Object {
        return null;
      } finally {
        // `remove` returns the removed cache entry's `Future<bool?>` —
        // already resolved (we're inside it) and never meant to be
        // awaited again; this is a cache-eviction call, not a kicked-off
        // async operation.
        // ignore: unawaited_futures
        _inFlight.remove(imagePath);
      }
    });
  }

  /// Releases the underlying native recognizer. Call when the owning scope
  /// (typically the DI container's lifetime) is done with this instance.
  Future<void> dispose() => _recognizer.close();
}
