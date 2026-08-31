import 'dart:convert';

import 'package:ai_ui_protocol/src/diagnostics/ai_ui_diagnostic.dart';
import 'package:ai_ui_protocol/src/validation/ai_ui_limits.dart';

/// Outcome of turning a raw payload string into a JSON object.
sealed class AiUiDecodeResult {
  const AiUiDecodeResult();
}

final class AiUiDecodeSuccess extends AiUiDecodeResult {
  const AiUiDecodeSuccess(this.json);

  final Map<String, dynamic> json;
}

final class AiUiDecodeFailure extends AiUiDecodeResult {
  const AiUiDecodeFailure(this.diagnostic);

  final AiUiDiagnostic diagnostic;
}

/// The size-guarded, total front door of the protocol.
///
/// [decode] has no `throw` path: bad bytes, bad JSON and a non-object root all
/// come back as [AiUiDecodeFailure]. Everything downstream can therefore
/// assume it is looking at a real object.
abstract final class AiUiCodec {
  /// Decodes [raw], rejecting anything over [AiUiLimits.maxPayloadBytes].
  ///
  /// The size check runs on the UTF-8 byte length rather than
  /// `String.length`, so a payload of Arabic text is measured the same way the
  /// wire measures it.
  static AiUiDecodeResult decode(
    String raw, {
    AiUiLimits limits = AiUiLimits.defaults,
  }) {
    final byteLength = utf8.encode(raw).length;
    if (byteLength > limits.maxPayloadBytes) {
      return AiUiDecodeFailure(
        AiUiDiagnostic(
          code: AiUiDiagnosticCode.limitExceeded,
          path: r'$',
          detail: 'payload $byteLength bytes > ${limits.maxPayloadBytes}',
        ),
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return AiUiDecodeFailure(
        AiUiDiagnostic(
          code: AiUiDiagnosticCode.malformedPayload,
          path: r'$',
          detail: 'not valid JSON',
        ),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return AiUiDecodeFailure(
        AiUiDiagnostic(
          code: AiUiDiagnosticCode.malformedPayload,
          path: r'$',
          detail: 'root is ${decoded.runtimeType}, expected object',
        ),
      );
    }

    return AiUiDecodeSuccess(decoded);
  }
}
