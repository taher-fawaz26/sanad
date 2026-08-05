import 'package:equatable/equatable.dart';

/// The organization's contact phone/email and their verification status.
class OrganizationContactEntity extends Equatable {
  const OrganizationContactEntity({
    this.phone,
    this.email,
    this.phoneVerified = false,
    this.emailVerified = false,
  });

  final String? phone;
  final String? email;
  final bool phoneVerified;
  final bool emailVerified;

  bool get isPhoneAdded => phone != null && phone!.isNotEmpty;
  bool get isEmailAdded => email != null && email!.isNotEmpty;

  @override
  List<Object?> get props => [phone, email, phoneVerified, emailVerified];
}
