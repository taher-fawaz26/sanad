part of 'contact_information_bloc.dart';

class ContactInformationState extends Equatable {
  const ContactInformationState({
    this.status = RequestStatus.initial,
    this.phone,
    this.email,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.failure,
  });

  final RequestStatus status;
  final String? phone;
  final String? email;
  final bool phoneVerified;
  final bool emailVerified;
  final Failure? failure;

  bool get isPhoneAdded => phone != null && phone!.isNotEmpty;
  bool get isEmailAdded => email != null && email!.isNotEmpty;

  ContactInformationState copyWith({
    RequestStatus? status,
    Object? phone = _sentinel,
    Object? email = _sentinel,
    bool? phoneVerified,
    bool? emailVerified,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ContactInformationState(
      status: status ?? this.status,
      phone: identical(phone, _sentinel) ? this.phone : phone as String?,
      email: identical(email, _sentinel) ? this.email : email as String?,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [
    status,
    phone,
    email,
    phoneVerified,
    emailVerified,
    failure,
  ];
}
