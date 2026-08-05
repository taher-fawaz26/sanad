import 'package:equatable/equatable.dart';

/// Body for `POST organizations/me/email/request-otp`.
class ContactEmailRequest extends Equatable {
  const ContactEmailRequest({required this.email});

  final String email;

  Map<String, dynamic> toMap() => {'email': email};

  @override
  List<Object?> get props => [email];
}
