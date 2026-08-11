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
    this.expiresAt,
    this.invitationLink,
  });

  final String id;
  final String fullName;
  final String role;
  final String initials;
  final InvitationStatus status;
  final String? phone;
  final String? email;
  final DateTime? invitedAt;
  final DateTime? expiresAt;
  final String? invitationLink;

  InvitationEntity copyWith({
    String? id,
    String? fullName,
    String? role,
    String? initials,
    InvitationStatus? status,
    String? phone,
    String? email,
    DateTime? invitedAt,
    DateTime? expiresAt,
    String? invitationLink,
  }) => InvitationEntity(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    role: role ?? this.role,
    initials: initials ?? this.initials,
    status: status ?? this.status,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    invitedAt: invitedAt ?? this.invitedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    invitationLink: invitationLink ?? this.invitationLink,
  );

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
    expiresAt,
    invitationLink,
  ];
}
