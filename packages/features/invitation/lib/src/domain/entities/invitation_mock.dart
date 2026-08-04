import 'package:equatable/equatable.dart';

/// Role offered in an invitation — mirrors the backend `workerType` values
/// used elsewhere in the app (`worker` | `manager`).
enum InvitationRole {
  worker,
  manager
  ;

  /// Localization key for the role label (`invitation.role_worker` /
  /// `invitation.role_manager`).
  String get labelKey => switch (this) {
    InvitationRole.worker => 'invitation.role_worker',
    InvitationRole.manager => 'invitation.role_manager',
  };
}

/// Temporary fixture standing in for the real invitation payload a deep link
/// will eventually deliver. UI-only — no repository, data source, or API
/// backs this model yet.
class InvitationMock extends Equatable {
  const InvitationMock({
    required this.organization,
    required this.inviter,
    required this.email,
    required this.role,
  });

  final String organization;
  final String inviter;
  final String email;
  final InvitationRole role;

  /// Default fixture used when the flow is opened without a specific
  /// [InvitationMock] (e.g. from the temporary settings entry point).
  static const sample = InvitationMock(
    organization: 'Horizon Ventures',
    inviter: 'Mohamed Khaled',
    email: 'john@example.com',
    role: InvitationRole.worker,
  );

  @override
  List<Object?> get props => [organization, inviter, email, role];
}
