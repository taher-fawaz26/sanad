import 'package:account_settings/src/data/models/deletion_blocker_dto.dart';
import 'package:account_settings/src/data/models/deletion_cascade_preview_dto.dart';
import 'package:account_settings/src/data/models/deletion_warning_dto.dart';
import 'package:account_settings/src/domain/entities/account_deletion_eligibility.dart';

/// `AccountDeletionEligibilityDto`.
class AccountDeletionEligibilityDto {
  const AccountDeletionEligibilityDto({
    required this.isEligible,
    required this.gracePeriodDays,
    required this.blockers,
    required this.warnings,
    required this.cascadePreview,
  });

  factory AccountDeletionEligibilityDto.fromJson(Map<String, dynamic> json) =>
      AccountDeletionEligibilityDto(
        isEligible: json['isEligible'] as bool? ?? false,
        gracePeriodDays: (json['gracePeriodDays'] as num?)?.toInt() ?? 0,
        blockers: (json['blockers'] as List<dynamic>? ?? const [])
            .map(
              (e) => DeletionBlockerDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        warnings: (json['warnings'] as List<dynamic>? ?? const [])
            .map(
              (e) => DeletionWarningDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        cascadePreview: DeletionCascadePreviewDto.fromJson(
          json['cascadePreview'] as Map<String, dynamic>? ?? const {},
        ),
      );

  final bool isEligible;
  final int gracePeriodDays;
  final List<DeletionBlockerDto> blockers;
  final List<DeletionWarningDto> warnings;
  final DeletionCascadePreviewDto cascadePreview;

  AccountDeletionEligibility toEntity() => AccountDeletionEligibility(
    isEligible: isEligible,
    gracePeriodDays: gracePeriodDays,
    blockers: blockers.map((e) => e.toEntity()).toList(),
    warnings: warnings.map((e) => e.toEntity()).toList(),
    cascadePreview: cascadePreview.toEntity(),
  );
}
