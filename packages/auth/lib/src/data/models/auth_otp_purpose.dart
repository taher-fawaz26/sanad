/// Backend values for `POST /auth/validate-otp`.
enum AuthOtpPurpose {
  register,
  forgotPassword;

  String get wireValue => switch (this) {
        AuthOtpPurpose.register => 'REGISTER',
        AuthOtpPurpose.forgotPassword => 'FORGOT_PASSWORD',
      };
}
