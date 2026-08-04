import 'package:equatable/equatable.dart';

/// Result of a successful `requestCode()` call.
class OtpDelivery extends Equatable {
  const OtpDelivery({this.maskedDestination, this.expiresIn});

  /// Destination as the backend chooses to display it (e.g. `j***@mail.com`).
  /// Falls back to `OtpFlowConfig.destination` when null.
  final String? maskedDestination;

  /// How long the issued code remains valid, if known.
  final Duration? expiresIn;

  @override
  List<Object?> get props => [maskedDestination, expiresIn];
}
