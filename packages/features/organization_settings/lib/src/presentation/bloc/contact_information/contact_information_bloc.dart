import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organization_settings/src/domain/usecases/get_organization_contact_usecase.dart';

part 'contact_information_event.dart';
part 'contact_information_state.dart';

/// Owns the organization's contact phone/email — loads them for the section
/// and refreshes them after a successful add/change (OTP verify commits the
/// new value server-side; this bloc re-pulls it as the source of truth).
class ContactInformationBloc
    extends Bloc<ContactInformationEvent, ContactInformationState> {
  ContactInformationBloc({required GetOrganizationContactUseCase getContact})
    : _getContact = getContact,
      super(const ContactInformationState()) {
    on<ContactInformationLoaded>(_onLoaded);
    on<ContactInformationRefreshed>(_onLoaded);
  }

  final GetOrganizationContactUseCase _getContact;

  Future<void> _onLoaded(
    ContactInformationEvent event,
    Emitter<ContactInformationState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final result = await _getContact(const NoParams()).run();

    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (contact) => emit(
        state.copyWith(
          status: RequestStatus.success,
          phone: contact.phone,
          email: contact.email,
          phoneVerified: contact.phoneVerified,
          emailVerified: contact.emailVerified,
        ),
      ),
    );
  }
}
