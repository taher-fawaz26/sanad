import 'package:domain/src/enums/user_role.dart';
import 'package:equatable/equatable.dart';

/// Core user aggregate — shared across authentication, profile, and settings.
///
/// This is a pure domain entity. No JSON serialization here.
/// Data-layer models extend this and add fromJson / toJson.
class UserEntity extends Equatable {
  /// Creates a [UserEntity] with all required identity fields.
  const UserEntity({
    required this.sub,
    required this.identifier,
    required this.identifierType,
    required this.isVerified,
    required this.isProfileCompleted,
    required this.role,
  });

  /// The subject identifier (e.g. UUID) issued by the auth provider.
  final String sub;

  /// The login identifier — phone number or email address.
  final String identifier;

  /// Discriminates the [identifier] kind, e.g. `"email"` or `"phone"`.
  final String identifierType;

  /// Whether the user has completed OTP / email verification.
  final bool isVerified;

  /// Whether the user has finished the onboarding profile flow.
  final bool isProfileCompleted;

  /// The account type assigned to this user.
  final UserRole role;

  /// Returns a copy of this entity with the given fields replaced.
  UserEntity copyWith({
    String? sub,
    String? identifier,
    String? identifierType,
    bool? isVerified,
    bool? isProfileCompleted,
    UserRole? role,
  }) =>
      UserEntity(
        sub: sub ?? this.sub,
        identifier: identifier ?? this.identifier,
        identifierType: identifierType ?? this.identifierType,
        isVerified: isVerified ?? this.isVerified,
        isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
        role: role ?? this.role,
      );

  @override
  List<Object?> get props => [
        sub,
        identifier,
        identifierType,
        isVerified,
        isProfileCompleted,
        role,
      ];
}
