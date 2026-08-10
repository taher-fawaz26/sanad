import 'package:equatable/equatable.dart';

/// `GET service-provider/overview` response counts —
/// `ServiceProviderOverviewCountsDto`.
class ProviderOverviewEntity extends Equatable {
  const ProviderOverviewEntity({
    required this.branchesCount,
    required this.servicesCount,
    required this.teamCount,
    required this.invitationsCount,
  });

  final int branchesCount;

  /// Mocked at `0` server-side until the services domain is refactored.
  final int servicesCount;
  final int teamCount;
  final int invitationsCount;

  @override
  List<Object?> get props => [
    branchesCount,
    servicesCount,
    teamCount,
    invitationsCount,
  ];
}
