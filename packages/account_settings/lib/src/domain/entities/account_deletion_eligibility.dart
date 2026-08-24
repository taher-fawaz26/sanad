import 'package:account_settings/src/domain/entities/deletion_blocker.dart';
import 'package:account_settings/src/domain/entities/deletion_cascade_preview.dart';
import 'package:account_settings/src/domain/entities/deletion_warning.dart';
import 'package:equatable/equatable.dart';

/// `AccountDeletionEligibilityDto` (`GET /account/deletion/eligibility`) —
/// drives the entire confirmation UI. Server-authoritative: the client never
/// hardcodes persona-specific deletion copy or cascade behavior.
class AccountDeletionEligibility extends Equatable {
  const AccountDeletionEligibility({
    required this.isEligible,
    required this.gracePeriodDays,
    required this.blockers,
    required this.warnings,
    required this.cascadePreview,
  });

  final bool isEligible;
  final int gracePeriodDays;
  final List<DeletionBlocker> blockers;
  final List<DeletionWarning> warnings;
  final DeletionCascadePreview cascadePreview;

  bool get hasBlockers => blockers.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  @override
  List<Object?> get props => [
    isEligible,
    gracePeriodDays,
    blockers,
    warnings,
    cascadePreview,
  ];
}
