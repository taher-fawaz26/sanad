import 'package:auth/auth.dart';
import 'package:sanad_provider/src/features/registration/src/domain/provider_type/provider_type_spec.dart';

/// The canonical list of supported provider types.
///
/// **To add a new type**: add one [ProviderTypeSpec] constant here.
/// No other file — no pages, routes, repository methods, or use-case branches —
/// needs to change.
///
/// All types share the single `MediaApiPaths.profile` endpoint;
/// [ProviderTypeSpec.userType] carries the wire discriminator the backend
/// uses to tell them apart.
abstract final class ProviderTypeRegistry {
  ProviderTypeRegistry._();

  /// Individual provider (freelancer / sole-trader).
  static const individual = ProviderTypeSpec(
    userType: UserType.individualProvider,
    requiresTradeLicence: false,
  );

  /// Company / organisation provider.
  static const company = ProviderTypeSpec(
    userType: UserType.organizationProvider,
    requiresTradeLicence: true,
  );

  // ── Future types (uncomment + add a matching UserType in auth) ──────────
  // static const clinic = ProviderTypeSpec(
  //   userType: UserType.clinicProvider,
  //   requiresTradeLicence: true,
  // );
}
