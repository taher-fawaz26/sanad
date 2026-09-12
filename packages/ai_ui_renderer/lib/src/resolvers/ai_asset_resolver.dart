import 'package:app_assets/app_assets.dart';
import 'package:equatable/equatable.dart';

/// A bundled asset the host is willing to let an AI payload reference.
final class AiUiAssetRef extends Equatable {
  const AiUiAssetRef.svg(this.path) : isSvg = true;
  const AiUiAssetRef.image(this.path) : isSvg = false;

  final String path;
  final bool isSvg;

  @override
  List<Object?> get props => [path, isSvg];
}

/// Maps a protocol `assetId` onto a real bundled asset.
///
/// The agent never sends a file path — it sends a stable id from a list the
/// host publishes, and an id outside that list is rejected during validation.
/// This is the same shape as `BackendIconResolver`: the backend names a thing,
/// the client decides whether that name means anything.
final class AiAssetResolver extends Equatable {
  const AiAssetResolver(this.assets);

  /// A small starting catalog. Extend it as the agent gains things to show;
  /// each addition is an additive protocol change needing no version bump.
  const AiAssetResolver.defaults()
    : assets = const {
        'image_placeholder': AiUiAssetRef.svg(AppSvgs.imagePlaceholder),
        'empty_state': AiUiAssetRef.image(AppImages.emptyState),
        'service_tools': AiUiAssetRef.image(AppImages.serviceTools),
        'no_branch_locations': AiUiAssetRef.image(AppImages.noBranchLocations),
        'ai_map_preview': AiUiAssetRef.image(AppImages.aiChatMapPreview),
        'ai_provider_avatar': AiUiAssetRef.image(AppImages.aiProviderAvatar),
        // Work-sample photographs an agent can attach to a provider card.
        // Ordinary bundled assets like every other entry — naming an id buys
        // no more reach than any other published name does.
        'work_photo_ac': AiUiAssetRef.image(AppImages.serviceCoverAc),
        'work_photo_plumbing': AiUiAssetRef.image(
          AppImages.serviceCoverPlumbing,
        ),
        'work_photo_electrical': AiUiAssetRef.image(
          AppImages.serviceCoverElectrical,
        ),
      };

  final Map<String, AiUiAssetRef> assets;

  /// Handed to `AiUiValidator.knownAssetIds` so an unpublished id is dropped
  /// before it reaches a widget.
  Set<String> get publishedIds => assets.keys.toSet();

  AiUiAssetRef? resolve(String assetId) => assets[assetId];

  @override
  List<Object?> get props => [assets];
}
