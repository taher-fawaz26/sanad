import 'package:otp/otp.dart' show OtpChannel;

/// The identifier type a client signs in with — `email` or `phone`.
///
/// [value] is the exact string the backend expects in the `method` field of
/// `POST auth/client/request-otp`, `GET auth/client/resend-info`, and
/// `POST auth/client/verify`. The unified client flow keys every step on this
/// plus the raw identifier `value`; there is no separate register/login path.
enum ClientAuthMethod {
  email('email'),
  phone('phone')
  ;

  const ClientAuthMethod(this.value);

  final String value;

  /// Maps the OTP UI's [OtpChannel] onto the wire `method`. The client OAuth
  /// route already carries the channel + destination, so verification reuses
  /// the exact same identifier the code was requested for.
  static ClientAuthMethod fromChannel(OtpChannel channel) => switch (channel) {
    OtpChannel.email => ClientAuthMethod.email,
    OtpChannel.phone => ClientAuthMethod.phone,
  };
}
