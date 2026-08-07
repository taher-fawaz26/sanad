import 'package:registration/src/domain/provider_type/provider_type_registry.dart' show ProviderTypeRegistry;

/// Describes the backend-facing configuration for a single provider type.
///
/// This is the entry point for extensibility: every provider type is declared
/// as a [ProviderTypeSpec] in [ProviderTypeRegistry]. Adding a new type
/// requires only a new registry entry — no changes to pages, routes, the
/// repository interface, or the use-case switch.
class ProviderTypeSpec {
  const ProviderTypeSpec({
    required this.profileEndpoint,
    required this.requiresTradeLicence,
  });

  /// `POST` path (relative to `/api/v1/`) for the profile-completion call.
  final String profileEndpoint;

  /// Whether this type's registration flow includes trade-licence capture.
  ///
  /// `true`  → show the org-details form + trade-licence upload step.
  /// `false` → show only the individual-details form.
  final bool requiresTradeLicence;
}
