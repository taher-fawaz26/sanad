import 'package:auth/auth.dart';
import 'package:sanad_provider/src/features/registration/src/domain/provider_type/provider_type_registry.dart'
    show ProviderTypeRegistry;

/// Describes the backend-facing configuration for a single provider type.
///
/// This is the entry point for extensibility: every provider type is declared
/// as a [ProviderTypeSpec] in [ProviderTypeRegistry]. Adding a new type
/// requires only a new registry entry — no changes to pages, routes, the
/// repository interface, or the use-case switch.
///
/// All provider types share a single profile-completion endpoint
/// (`MediaApiPaths.profile`, i.e. `POST auth/profile`); [userType] is the
/// discriminator sent in the request body (`CreateProviderProfileDto.userType`)
/// that tells the backend which shape of the payload to expect.
class ProviderTypeSpec {
  const ProviderTypeSpec({
    required this.userType,
    required this.requiresTradeLicence,
  });

  /// Wire discriminator sent as `userType` in the profile-completion body.
  final UserType userType;

  /// Whether this type's registration flow includes trade-licence capture.
  ///
  /// `true`  → show the org-details form + trade-licence upload step.
  /// `false` → show only the individual-details form.
  final bool requiresTradeLicence;
}
