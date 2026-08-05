import 'package:equatable/equatable.dart';

/// Body for `POST organizations/me/phone/request-otp`.
class ContactPhoneRequest extends Equatable {
  const ContactPhoneRequest({required this.phone});

  final String phone;

  Map<String, dynamic> toMap() => {'phone': phone};

  @override
  List<Object?> get props => [phone];
}
