import 'package:equatable/equatable.dart';

/// Body for `POST organizations/me/phone/verify`.
class VerifyPhoneRequest extends Equatable {
  const VerifyPhoneRequest({required this.phone, required this.otp});

  final String phone;
  final String otp;

  Map<String, dynamic> toMap() => {'phone': phone, 'otp': otp};

  @override
  List<Object?> get props => [phone, otp];
}
