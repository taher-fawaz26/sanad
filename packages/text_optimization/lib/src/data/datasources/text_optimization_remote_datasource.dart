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

  /// The authenticated [BaseApiClient] for the Sanad backend's enhance-text
  /// endpoint — see `NetworkDI.textOptimizationApiClientInstanceName`. The
  /// bearer token is attached by `AuthInterceptor`; this layer never touches
  /// tokens directly.
  final BaseApiClient _client;

  @override
  TaskEither<Failure, String> optimize(String text) => _client.request<String>(
    path: TextOptimizationApiConfig.enhanceTextPath,
    method: RequestMethod.post,
    // The endpoint's only accepted property is `text` (5–256 chars,
    // validated server-side). Never send `model` or any other field.
    body: {'text': text},
    parser: _parseEnhancedText,
  );

  /// The endpoint returns `{"enhanced_text": "..."}`. Only that field is read,
  /// by name; any additional (future) fields are ignored so the client stays
  /// decoupled from undocumented response properties. An unexpected shape is a
  /// [FormatException], mapped by [ErrorMapper] to [UnknownFailure].
  static String _parseEnhancedText(dynamic data) {
    if (data is Map && data['enhanced_text'] is String) {
      return (data['enhanced_text'] as String).trim();
    }
    throw const FormatException(
      'Unexpected /agent/enhance-text response shape',
    );
  }
}
