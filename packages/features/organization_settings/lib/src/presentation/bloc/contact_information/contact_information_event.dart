part of 'contact_information_bloc.dart';

sealed class ContactInformationEvent extends Equatable {
  const ContactInformationEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load — fetches the organization's current contact info.
final class ContactInformationLoaded extends ContactInformationEvent {
  const ContactInformationLoaded();
}

/// Re-fetches contact info after a successful add/change (phone or email).
final class ContactInformationRefreshed extends ContactInformationEvent {
  const ContactInformationRefreshed();
}
