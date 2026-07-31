import 'package:auth/src/data/models/profiles/client_profile_model.dart';
import 'package:auth/src/data/models/profiles/company_provider_profile_model.dart';
import 'package:auth/src/data/models/profiles/individual_provider_profile_model.dart';
import 'package:auth/src/data/models/profiles/worker_profile_model.dart';
import 'package:auth/src/domain/entities/auth_profile_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';

/// Resolves the Swagger `oneOf` profile payload using [UserType].
///
/// Returns a concrete model that **is** an [AuthProfileEntity] (inheritance,
/// no separate mapper).
abstract final class AuthProfileFactory {
  AuthProfileFactory._();

  static AuthProfileEntity fromJson({
    required UserType type,
    required Map<String, dynamic> json,
  }) {
    switch (type) {
      case UserType.client:
        return ClientProfileModel.fromJson(json);
      case UserType.individualProvider:
        return IndividualProviderProfileModel.fromJson(json);
      case UserType.companyProvider:
        return CompanyProviderProfileModel.fromJson(json);
      case UserType.worker:
        return WorkerProfileModel.fromJson(json);
      case UserType.admin:
        throw ArgumentError(
          'UserType.admin has no AuthProfile payload in the API oneOf.',
        );
    }
  }

  /// Serializes a profile produced by [fromJson] (always a model instance).
  static Map<String, dynamic> toJson(AuthProfileEntity profile) {
    if (profile is ClientProfileModel) return profile.toJson();
    if (profile is IndividualProviderProfileModel) return profile.toJson();
    if (profile is CompanyProviderProfileModel) return profile.toJson();
    if (profile is WorkerProfileModel) return profile.toJson();
    throw StateError(
      'Expected a profile model for JSON serialization, '
      'got ${profile.runtimeType}',
    );
  }
}
