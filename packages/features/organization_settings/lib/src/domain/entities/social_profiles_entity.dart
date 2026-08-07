import 'package:equatable/equatable.dart';

/// The organization's social profile links.
///
/// Backend returns this as a free-form `Map<String, String>` (`socialLinks`,
/// including `website` when provided) rather than a fixed schema — this
/// entity gives the known keys a stable shape for the UI. Any additional
/// keys the backend adds later are simply not surfaced until a field is
/// added here.
class SocialProfilesEntity extends Equatable {
  const SocialProfilesEntity({
    this.facebook,
    this.tiktok,
    this.instagram,
    this.x,
    this.websiteUrl,
  });

  final String? facebook;
  final String? tiktok;
  final String? instagram;

  /// The `x` key (formerly Twitter) — matches the backend's social key set
  /// exactly: `facebook, x, tiktok, instagram, website`.
  final String? x;
  final String? websiteUrl;

  @override
  List<Object?> get props => [facebook, tiktok, instagram, x, websiteUrl];
}
