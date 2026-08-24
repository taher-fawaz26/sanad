import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

// Base class pattern: single abstract method is intentional by design.
// ignore: one_member_abstracts
abstract class TextOptimizationRemoteDataSource {
  TaskEither<Failure, String> optimize(String text);
}

class TextOptimizationRemoteDataSourceImpl
    implements TextOptimizationRemoteDataSource {
  const TextOptimizationRemoteDataSourceImpl(this._client);

  /// The unauthenticated [BaseApiClient] scoped to
  /// [TextOptimizationApiConfig.baseUrl] — see
  /// `NetworkDI.textOptimizationApiClientInstanceName`.
  final BaseApiClient _client;

  @override
  TaskEither<Failure, String> optimize(String text) => _client.request<String>(
    path: TextOptimizationApiConfig.optimizePath,
    method: RequestMethod.post,
    body: {'text': text},
    parser: _parseOptimizedText,
  );

  /// The API returns the optimized text as a plain/JSON-string body, never
  /// `{"text": "..."}` (SAN-578's contract). Dio's default JSON transformer
  /// already unquotes a JSON-string response into a Dart [String]; a body
  /// that isn't valid JSON falls back to the same raw-string shape. A
  /// `{"text": ...}` object is still accepted defensively in case the
  /// backend's contract ever drifts — everything else is an unexpected
  /// format, mapped by [ErrorMapper] to [UnknownFailure].
  static String _parseOptimizedText(dynamic data) {
    if (data is String) return data.trim();
    if (data is Map && data['text'] is String) {
      return (data['text'] as String).trim();
    }
    throw const FormatException('Unexpected /optimize response shape');
  }
}
