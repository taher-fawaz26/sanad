import 'package:registration/src/domain/provider_type/provider_type_spec.dart';

/// The canonical list of supported provider types.
///
/// **To add a new type**: add one [ProviderTypeSpec] constant here.
/// No other file — no pages, routes, repository methods, or use-case branches —
/// needs to change.
///
/// Endpoint strings mirror [MediaApiPaths] constants; they're inlined here
/// so the domain layer carries no dependency on the data layer.
abstract final class ProviderTypeRegistry {
  ProviderTypeRegistry._();

  /// Individual provider (freelancer / sole-trader).
  static const individual = ProviderTypeSpec(
    profileEndpoint: 'auth/profile/individual-provider',
    requiresTradeLicence: false,
  );

  /// Company / organisation provider.
  static const company = ProviderTypeSpec(
    profileEndpoint: 'auth/profile/company-provider',
    requiresTradeLicence: true,
  );

  // ── Future types (uncomment + add a matching UserType in auth) ──────────
  // static const clinic = ProviderTypeSpec(
  //   profileEndpoint: 'auth/profile/clinic-provider',
  //   requiresTradeLicence: true,
  // );
}
