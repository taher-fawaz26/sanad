/// Backend `purpose` values for OTP validate / resend.
enum OtpPurpose {
  register,
  forgotPassword;

  String get wireValue => switch (this) {
        OtpPurpose.register => 'REGISTER',
        OtpPurpose.forgotPassword => 'FORGOT_PASSWORD',
      };
}
