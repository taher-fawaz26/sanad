import 'package:equatable/equatable.dart';

/// Body for `POST /auth/validate-info`.
class ValidateEmailRequest extends Equatable {
  const ValidateEmailRequest({required this.email});

  final String email;

  Map<String, dynamic> toMap() => {'email': email};

  @override
  List<Object?> get props => [email];
}
