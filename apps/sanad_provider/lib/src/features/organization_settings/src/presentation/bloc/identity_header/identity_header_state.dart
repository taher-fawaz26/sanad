part of 'identity_header_bloc.dart';

class IdentityHeaderState extends Equatable {
  const IdentityHeaderState({
    this.cover = const IdentityMediaSlotState(),
    this.logo = const IdentityMediaSlotState(),
  });

  final IdentityMediaSlotState cover;
  final IdentityMediaSlotState logo;

  IdentityMediaSlotState slot(OrganizationMediaSlot slot) =>
      slot == OrganizationMediaSlot.cover ? cover : logo;

  IdentityHeaderState copyWithSlot(
    OrganizationMediaSlot slot,
    IdentityMediaSlotState value,
  ) {
    return switch (slot) {
      OrganizationMediaSlot.cover => IdentityHeaderState(
        cover: value,
        logo: logo,
      ),
      OrganizationMediaSlot.logo => IdentityHeaderState(
        cover: cover,
        logo: value,
      ),
    };
  }

  @override
  List<Object?> get props => [cover, logo];
}
