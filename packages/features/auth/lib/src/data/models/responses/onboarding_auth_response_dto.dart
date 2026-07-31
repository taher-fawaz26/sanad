import 'package:auth/src/data/models/user_model.dart';

class OnboardingAuthResponseModel {
  final String status;
  final String onboardingToken;
  final bool isEmailVerified;
  final bool isProfileCreated;
  final UserModel user;

  const OnboardingAuthResponseModel({
    required this.status,
    required this.onboardingToken,
    required this.isEmailVerified,
    required this.isProfileCreated,
    required this.user,
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
    'user': user.toJson(),
  };
}
