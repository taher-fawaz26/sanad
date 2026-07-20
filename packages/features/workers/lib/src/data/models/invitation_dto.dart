import 'package:core/core.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/invitation_status.dart';

class InvitationDto extends InvitationEntity
    implements EntityConverter<InvitationEntity> {
  const InvitationDto({
    required super.id,
    required super.fullName,
    required super.role,
    required super.initials,
    super.status,
    super.phone,
    super.email,
    super.invitedAt,
    super.expiresAt,
  });

  factory InvitationDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final createdAt = json['createdAt'] as String?;
    final expiresAt = json['expiresAt'] as String?;
    return InvitationDto(
      id: json['id'] as String,
      fullName: name,
      role: json['workerType'] as String? ?? 'worker',
      initials: _initials(name),
      status: InvitationStatus.fromString(json['status'] as String?),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      invitedAt: createdAt != null ? DateTime.tryParse(createdAt) : null,
      expiresAt: expiresAt != null ? DateTime.tryParse(expiresAt) : null,
    );
  }

  @override
  InvitationEntity toEntity() => InvitationEntity(
    id: id,
    fullName: fullName,
    role: role,
    initials: initials,
    status: status,
    phone: phone,
    email: email,
    invitedAt: invitedAt,
    expiresAt: expiresAt,
  );

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    return words
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
  }
}
