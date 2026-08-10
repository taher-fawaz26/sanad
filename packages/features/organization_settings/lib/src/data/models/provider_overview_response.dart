import 'package:organization_settings/src/domain/entities/provider_overview_entity.dart';

/// Mirrors `ServiceProviderOverviewCountsDto` exactly.
class ProviderOverviewCountsResponse {
  const ProviderOverviewCountsResponse({
    required this.branchesCount,
    required this.servicesCount,
    required this.teamCount,
    required this.invitationsCount,
  });

  factory ProviderOverviewCountsResponse.fromJson(Map<String, dynamic> json) =>
      ProviderOverviewCountsResponse(
        branchesCount: json['branchesCount'] as int,
        servicesCount: json['servicesCount'] as int,
        teamCount: json['teamCount'] as int,
        invitationsCount: json['invitationsCount'] as int,
      );

  final int branchesCount;
  final int servicesCount;
  final int teamCount;
  final int invitationsCount;

  ProviderOverviewEntity toEntity() => ProviderOverviewEntity(
    branchesCount: branchesCount,
    servicesCount: servicesCount,
    teamCount: teamCount,
    invitationsCount: invitationsCount,
  );
}

/// Mirrors `ServiceProviderOverviewResponseDto` exactly —
/// `GET service-provider/overview`.
class ProviderOverviewResponse {
  const ProviderOverviewResponse({required this.counts});

  factory ProviderOverviewResponse.fromJson(Map<String, dynamic> json) =>
      ProviderOverviewResponse(
        counts: ProviderOverviewCountsResponse.fromJson(
          json['counts'] as Map<String, dynamic>,
        ),
      );

  final ProviderOverviewCountsResponse counts;

  ProviderOverviewEntity toEntity() => counts.toEntity();
}
