part of 'invitations_list_bloc.dart';

sealed class InvitationsListEvent extends Equatable {
  const InvitationsListEvent();

  @override
  List<Object?> get props => [];
}

final class InvitationsListFetchEvent extends InvitationsListEvent {
  const InvitationsListFetchEvent();
}

final class InvitationsListRefreshEvent extends InvitationsListEvent {
  const InvitationsListRefreshEvent();
}

final class InvitationsListLoadMoreEvent extends InvitationsListEvent {
  const InvitationsListLoadMoreEvent();
}

final class InvitationsListSearchChangedEvent extends InvitationsListEvent {
  const InvitationsListSearchChangedEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class InvitationRemovedFromListEvent extends InvitationsListEvent {
  const InvitationRemovedFromListEvent(this.invitationId);

  final String invitationId;

  @override
  List<Object?> get props => [invitationId];
}

final class InvitationCancelledInListEvent extends InvitationsListEvent {
  const InvitationCancelledInListEvent(this.invitationId);

  final String invitationId;

  @override
  List<Object?> get props => [invitationId];
}
