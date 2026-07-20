import 'package:equatable/equatable.dart';
import 'package:workers/src/domain/entities/invitation_status.dart';

class InvitationEntity extends Equatable {
  const InvitationEntity({
    required this.id,
    required this.fullName,
    required this.role,
    required this.initials,
    this.status = InvitationStatus.pending,
    this.phone,
    this.email,
    this.invitedAt,
  });

  final String id;
  final String fullName;
  final String role;
  final String initials;
  final InvitationStatus status;
  final String? phone;
  final String? email;
  final DateTime? invitedAt;

  @override
  List<Object?> get props => [
    id,
    fullName,
    role,
    initials,
    status,
    phone,
    email,
    invitedAt,
  ];
}
