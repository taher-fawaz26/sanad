/// Shared raster image asset paths shipped under
/// `packages/app_assets/assets/images/`.
///
/// Load with `Image.asset(AppImages.x, package: AppAssets.package)`.
abstract final class AppImages {
  AppImages._();

  static const String _base = 'assets/images';

  /// Figma `empty states / internet` (`321:8297`) — no network connection.
  static const String networkFailure =
      '$_base/empty_states/network_failure.png';

  /// Figma `empty states / No branches yet` (`328:9898`) — generic empty.
  static const String emptyState = '$_base/empty_states/empty_state.png';

  /// Figma `empty states / No branch locations` (`347:13862`).
  static const String noBranchLocations =
      '$_base/branches/no_branch_locations.png';

  /// Figma add-branch workers empty state (`245:6400`).
  static const String addWorkers = '$_base/workers/worker.png';

  /// Wrench & screwdriver — services empty state (`347:13959`).
  static const String serviceTools = '$_base/services/service_tools.png';

  static const String addServices = '$_base/illustrations/add_services.svg';

  /// UAE Dirham mark — services dashboard revenue metric (`4715:26102`).
  static const String dirham = '$_base/services/dirham.png';

  /// Sample service cover — AC Repair (`4715:26252`).
  static const String serviceCoverAc = '$_base/services/service_cover_ac.jpg';

  /// Sample service cover — Plumbing (`4715:26141`).
  static const String serviceCoverPlumbing =
      '$_base/services/service_cover_plumbing.jpg';

  /// Sample service cover — Electrical (`4715:26171`).
  static const String serviceCoverElectrical =
      '$_base/services/service_cover_electrical.jpg';

  /// Emirates ID front capture preview — Scan flow (`2897:13628`).
  static const String emiratesIdFrontPreview =
      '$_base/registration/emirates_id_front_preview.png';

  /// Stand-in profile portrait for the AI Chat header and user message rows
  /// — Figma `header-profile` (`7124:29693`) / `avatar` (`6695:44807`).
  ///
  /// A **placeholder**, shown only until a real account avatar is available;
  /// it is the likeness used in the design file, so treat it as mockup
  /// artwork rather than shipped product imagery and swap it for the signed-in
  /// user's own photo as soon as the profile API provides one.
  static const String aiChatProfileAvatarPlaceholder =
      '$_base/ai_chat/profile_avatar_placeholder.png';

  /// Provider portrait used by the AI chat's contextual offers — Figma
  /// `avatar` (`8433:38327`).
  ///
  /// Mockup artwork, exactly like [aiChatProfileAvatarPlaceholder]: it stands
  /// in until offers carry a real provider photo from the backend.
  static const String aiProviderAvatar =
      '$_base/ai_chat/ai_provider_avatar.png';

  /// The green bloom behind the AI hero mark — Figma `bg` (`8245:35005`),
  /// the background instance inside `Frame 427319459` (`7118:29598`).
  ///
  /// A **PNG, not an SVG**: the design is two gradient shapes under a
  /// `feGaussianBlur`, and `flutter_svg` does not implement SVG filters — a
  /// vector export of this node renders as two hard-edged blobs. Figma's own
  /// raster of the node is the design, blur included, on a fully transparent
  /// ground.
  ///
  /// 267 square for a 200dp node: the extra 33.5 on each side is the blur's
  /// bleed outside the frame, so the asset must be drawn at 267dp for the
  /// glow to land where the design puts it.
  static const String aiChatHeroBloom = '$_base/ai_chat/ai_hero_bloom.png';

  /// Map illustration behind the AI chat's location prompts — Figma
  /// `illustration-container` (`7960:31577` / `7960:31628`).
  ///
  /// A **static preview**, not a live map. It is what the `permission_request`
  /// and `location_confirm` components draw when the renderer has no map
  /// engine available, which is the case in the design catalog and in every
  /// widget test. An app that can draw a real map registers its own renderer
  /// over those node types instead.
  static const String aiChatMapPreview = '$_base/ai_chat/ai_map_preview.png';
}
