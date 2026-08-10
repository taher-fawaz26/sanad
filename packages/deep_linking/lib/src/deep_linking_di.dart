import 'package:core/core.dart';
import 'package:deep_linking/src/deep_link_config.dart';
import 'package:deep_linking/src/deep_linking_service.dart';
import 'package:deep_linking/src/deep_linking_service_impl.dart';

/// Registers deep-linking bindings into the global [sl] service locator.
abstract final class DeepLinkingDI {
  const DeepLinkingDI._();

  /// Registers a [DeepLinkConfig] and [DeepLinkingService] for [config].
  static void init({required DeepLinkConfig config}) {
    sl
      ..registerLazySingleton<DeepLinkConfig>(() => config)
      ..registerLazySingleton<DeepLinkingService>(
        () => DeepLinkingServiceImpl(config: config),
      );
  }
}
