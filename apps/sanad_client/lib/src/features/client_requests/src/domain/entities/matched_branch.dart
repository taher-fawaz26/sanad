import 'package:equatable/equatable.dart';

/// A provider branch the request was matched to at submit time.
///
/// Matching runs once, on submit, and the result is frozen — including
/// [distanceKm], which is a straight-line figure captured then, not a live
/// measurement.
class MatchedBranch extends Equatable {
  /// Creates a matched branch.
  const MatchedBranch({
    required this.branchId,
    required this.branchName,
    required this.providerId,
    required this.providerName,
    required this.distanceKm,
  });

  /// The branch that would do the work.
  final String branchId;

  /// Branch display name, localized server-side.
  final String branchName;

  /// The company that owns the branch.
  final String providerId;

  /// Provider display name, localized server-side.
  final String providerName;

  /// Straight-line distance captured at match time.
  final double distanceKm;

  @override
  List<Object?> get props => [
    branchId,
    branchName,
    providerId,
    providerName,
    distanceKm,
  ];
}
