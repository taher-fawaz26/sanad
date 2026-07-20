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
  });

  factory InvitationDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return InvitationDto(
      id: json['id'] as String,
      fullName: name,
      role: json['type'] as String? ?? 'worker',
      initials: _initials(name),
      status: InvitationStatus.fromString(json['status'] as String?),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      invitedAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
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
