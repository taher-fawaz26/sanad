import 'package:equatable/equatable.dart';

/// Base type for the Swagger `oneOf` auth profile payload.
///
/// The backend's `profile` oneOf has exactly three shapes — client, worker,
/// and a single "business provider" shape shared by BOTH individual and
/// company provider accounts. Concrete, sealed implementations live in the
/// data layer: see `AuthProfileModel` and its three variants
/// (`ClientProfileModel`, `WorkerProfileModel`, `BusinessProviderProfileModel`)
/// in `data/models/profiles/auth_profile_model.dart`, selected by
/// `UserType` via `AuthProfileModel.fromJson`.
///
/// Kept as an unsealed marker here (no fields) — the sealed hierarchy and its
/// direct subtypes must live in the same library file per Dart's `sealed`
/// same-library rule, and that hierarchy is a data-layer parsing concern.
abstract class AuthProfileEntity extends Equatable {
  const AuthProfileEntity();
}
