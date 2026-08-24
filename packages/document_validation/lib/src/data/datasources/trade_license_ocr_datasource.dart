import 'dart:io';

import 'package:document_validation/src/domain/policies/trade_license_signal_policy.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

/// Wraps `flutter_tesseract_ocr` behind the package boundary — the only file
/// in this repository allowed to reference `package:flutter_tesseract_ocr`.
///
/// OCR output is a **pre-upload classification signal only**: it is fed to
/// [TradeLicenseSignalPolicy], never surfaced to the user or persisted, and
/// never used to replace the backend's own Trade License extraction.
///
/// Bilingual (`ara+eng`) so an English, Arabic, or mixed-language Trade
/// License is read in one pass — see `assets/tessdata_config.json` in this
/// package for the bundled trained-data files.
class TradeLicenseOcrDataSource {
  TradeLicenseOcrDataSource();

  static const _language = 'ara+eng';

  /// In-flight OCR calls keyed by file path, so a repeated tap on the same
  /// just-picked file (double-tap, rebuild) reuses the same run rather than
  /// invoking the native OCR engine twice concurrently.
  final Map<String, Future<bool?>> _inFlight = {};

  /// Returns `true` when [imagePath] reads as a Trade License, `false` when
  /// it confidently does not (including OCR output too sparse to classify
  /// confidently — the caller asks the user to retry with a clearer image),
  /// or `null` when the OCR engine itself failed to run — the caller maps
  /// `null` to a `VALIDATION_ENGINE_ERROR`, distinct from a confident
  /// rejection.
  Future<bool?> looksLikeTradeLicense(String imagePath) {
    return _inFlight.putIfAbsent(imagePath, () async {
      try {
        final file = File(imagePath);
        if (!file.existsSync()) return null;

        final text = await FlutterTesseractOcr.extractText(
          imagePath,
          language: _language,
        );
        return TradeLicenseSignalPolicy.evaluate(text);
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
}
