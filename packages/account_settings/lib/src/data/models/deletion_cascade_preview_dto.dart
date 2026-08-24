import 'package:account_settings/src/domain/entities/deletion_cascade_preview.dart';
import 'package:account_settings/src/domain/enums/deletion_persona.dart';

const _knownCascadeFields = {
  'persona',
  'branches',
  'services',
  'teamAccounts',
  'invitations',
  'documents',
  'media',
  'branchesUnassigned',
};

/// `DeletionCascadePreviewDto`.
class DeletionCascadePreviewDto {
  const DeletionCascadePreviewDto({
    required this.persona,
    required this.branches,
    required this.services,
    required this.teamAccounts,
    required this.invitations,
    required this.documents,
    required this.media,
    required this.branchesUnassigned,
    this.extraCounts = const {},
  });

  factory DeletionCascadePreviewDto.fromJson(Map<String, dynamic> json) {
    final extra = <String, int>{};
    for (final entry in json.entries) {
      if (_knownCascadeFields.contains(entry.key)) continue;
      final value = entry.value;
      if (value is num) extra[entry.key] = value.toInt();
    }
    return DeletionCascadePreviewDto(
      persona: json['persona'] as String? ?? '',
      branches: (json['branches'] as num?)?.toInt() ?? 0,
      services: (json['services'] as num?)?.toInt() ?? 0,
      teamAccounts: (json['teamAccounts'] as num?)?.toInt() ?? 0,
      invitations: (json['invitations'] as num?)?.toInt() ?? 0,
      documents: (json['documents'] as num?)?.toInt() ?? 0,
      media: (json['media'] as num?)?.toInt() ?? 0,
      branchesUnassigned: (json['branchesUnassigned'] as num?)?.toInt() ?? 0,
      extraCounts: extra,
    );
  }

  final String persona;
  final int branches;
  final int services;
  final int teamAccounts;
  final int invitations;
  final int documents;
  final int media;
  final int branchesUnassigned;

  /// Numeric fields beyond the known contract — preserved, never dropped.
  final Map<String, int> extraCounts;

  DeletionCascadePreview toEntity() => DeletionCascadePreview(
    persona: DeletionPersona.fromApi(persona),
    branches: branches,
    services: services,
    teamAccounts: teamAccounts,
    invitations: invitations,
    documents: documents,
    media: media,
    branchesUnassigned: branchesUnassigned,
    extraCounts: extraCounts,
  );
}
