import 'package:account_settings/src/domain/enums/deletion_persona.dart';
import 'package:equatable/equatable.dart';

/// `DeletionCascadePreviewDto` — live counts of everything the deletion will
/// soft-delete. Authoritative over any client-side persona/role guess; the
/// UI renders exactly what this carries, including any unrecognized numeric
/// field the backend adds later ([extraCounts]) rather than dropping it.
class DeletionCascadePreview extends Equatable {
  const DeletionCascadePreview({
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

  final DeletionPersona persona;
  final int branches;
  final int services;
  final int teamAccounts;
  final int invitations;
  final int documents;
  final int media;
  final int branchesUnassigned;

  /// Any additional numeric fields the backend returns beyond the known
  /// contract — rendered rather than silently dropped.
  final Map<String, int> extraCounts;

  bool get isOrganizationOwner => persona == DeletionPersona.companyProvider;

  @override
  List<Object?> get props => [
    persona,
    branches,
    services,
    teamAccounts,
    invitations,
    documents,
    media,
    branchesUnassigned,
    extraCounts,
  ];
}
