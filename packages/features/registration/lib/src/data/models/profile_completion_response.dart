import 'package:auth/auth.dart';

/// Parses the profile completion response into [AuthSessionEntity].
///
/// Profile creation endpoints return the same authenticated-session shape
/// as email verification when successful.
abstract final class ProfileCompletionResponse {
  ProfileCompletionResponse._();

  static AuthSessionEntity fromJson(Map<String, dynamic> json) {
    final response = AuthResponseModel.fromJson(json);
    if (response is! AuthSessionEntity) {
      throw FormatException(
        'Expected AuthSessionEntity from profile completion, '
        'got ${response.runtimeType}',
      );
    }
    return response;
  }
}
