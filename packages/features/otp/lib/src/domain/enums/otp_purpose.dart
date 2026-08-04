/// Why verification is happening. Drives default copy (title/subtitle) —
/// purely presentational, never changes verification behavior.
enum OtpPurpose {
  verifyEmail,
  changeEmail,
  verifyPhone,
  changePhone,
  login,
  passwordReset,
  deleteAccount,
  mfa,
  custom,
}
