import 'package:equatable/equatable.dart';

/// Account type the registering user selects on the third step.
enum RegistrationAccountType { organization, individual }

/// Immutable state carried across the sign-up flow by RegistrationCubit.
class RegistrationState extends Equatable {
  const RegistrationState({this.email = '', this.accountType});

  final String email;
  final RegistrationAccountType? accountType;

  RegistrationState copyWith({
    String? email,
    RegistrationAccountType? accountType,
  }) =>
      RegistrationState(
        email: email ?? this.email,
        accountType: accountType ?? this.accountType,
      );

  @override
  List<Object?> get props => [email, accountType];
}
