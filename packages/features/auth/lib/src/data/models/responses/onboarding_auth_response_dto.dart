import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';

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
    return OnboardingAuthResponseModel(
      status: json['status'] as String,
      onboardingToken: json['onboardingToken'] as String,
      isEmailVerified: json['isEmailVerified'] as bool,
      isProfileCreated: json['isProfileCreated'] as bool,
      user: UserModel.fromJson(
        json['user'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'onboardingToken': onboardingToken,
        'isEmailVerified': isEmailVerified,
        'isProfileCreated': isProfileCreated,
        'user': (user as UserModel).toJson(),
      };
}
