import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registration/src/presentation/cubit/registration_state.dart';

/// Carries cross-step registration data (email, account type) throughout the
/// sign-up flow. A fresh instance is created per ShellRoute entry in
/// RegistrationModule.
class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit() : super(const RegistrationState());

  void setEmail(String email) => emit(state.copyWith(email: email));

  void setAccountType(RegistrationAccountType type) =>
      emit(state.copyWith(accountType: type));
}
