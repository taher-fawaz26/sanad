import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/enums/auth_session_status.dart';

/// Data model for [OnboardingAuthEntity] — inherits fields, adds JSON I/O.
class OnboardingAuthResponseModel extends OnboardingAuthEntity {
  const OnboardingAuthResponseModel({
    required super.status,
    required super.onboardingToken,
    required super.isEmailVerified,
    required super.isProfileCreated,
    required super.user,
  });

  factory OnboardingAuthResponseModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    if (rawStatus is! String) {
      throw const FormatException(
        'OnboardingAuthResponseDto.status is required and must be a string.',
      );
    }
    final rawUser = json['user'];
    if (rawUser is! Map) {
      throw const FormatException(
        'OnboardingAuthResponseDto.user is required and must be an object.',
      );
    }
    return OnboardingAuthResponseModel(
      status: AuthSessionStatus.fromString(rawStatus),
      onboardingToken: json['onboardingToken'] as String,
      // The live `OnboardingAuthResponseDto` (signup/verify, social/signup)
      // has no `isEmailVerified` field at all — default rather than throw so
      // this DTO doesn't crash on a schema it was never actually part of.
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isProfileCreated: json['isProfileCreated'] as bool,
      user: UserModel.fromJson(Map<String, dynamic>.from(rawUser)),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.value,
    'onboardingToken': onboardingToken,
    'isEmailVerified': isEmailVerified,
    'isProfileCreated': isProfileCreated,
    'user': (user as UserModel).toJson(),
  };
}
