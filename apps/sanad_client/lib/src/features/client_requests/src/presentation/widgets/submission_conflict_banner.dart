import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_date_time_picker.dart';

/// Explains why a submission found nothing, and offers the recovery that
/// matches the reason.
///
/// The backend answers `409` with one of three codes precisely because the
/// next user action differs. Collapsing them into one "could not submit"
/// message would throw that away:
///
/// * `NO_PROVIDERS_FOR_SERVICE` — nobody offers this service, so change it.
/// * `NO_COVERAGE` — providers exist but not here, so change the address.
/// * `OUTSIDE_HOURS` — they are closed then, so here are windows that work.
class SubmissionConflictBanner extends StatelessWidget {
  /// Creates the banner.
  const SubmissionConflictBanner({
    required this.conflict,
    required this.onChangeService,
    required this.onChangeLocation,
    required this.onPickAlternative,
    super.key,
  });

  /// The parsed conflict.
  final RequestSubmissionConflict conflict;

  /// Opens the service picker.
  final VoidCallback onChangeService;

  /// Opens the location picker.
  final VoidCallback onChangeLocation;

  /// Adopts one of the offered windows as the preferred time.
  final ValueChanged<DateTime> onPickAlternative;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    final (title, description) = switch (conflict.code) {
      RequestSubmissionConflictCode.noProvidersForService => (
        'client_requests.conflict_no_providers_title'.tr(),
        'client_requests.conflict_no_providers_description'.tr(),
      ),
      RequestSubmissionConflictCode.noCoverage => (
        'client_requests.conflict_no_coverage_title'.tr(),
        'client_requests.conflict_no_coverage_description'.tr(),
      ),
      RequestSubmissionConflictCode.outsideHours => (
        'client_requests.conflict_outside_hours_title'.tr(),
        'client_requests.conflict_outside_hours_description'.tr(),
      ),
      // An unrecognised 409 — most often "already submitted". The server's own
      // prose is the most useful thing available.
      RequestSubmissionConflictCode.unknown => (
        'client_requests.conflict_generic_title'.tr(),
        conflict.message,
      ),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.error50,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: typography.titleSmall),
          SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: typography.bodySmall.copyWith(color: colors.slate600),
          ),
          ..._recovery(context),
        ],
      ),
    );
  }

  List<Widget> _recovery(BuildContext context) => switch (conflict.code) {
    RequestSubmissionConflictCode.noProvidersForService => [
      SizedBox(height: AppSpacing.md),
      AppButton(
        label: 'client_requests.conflict_no_providers_cta'.tr(),
        onPressed: onChangeService,
        variant: AppButtonVariant.secondary,
        size: AppButtonSize.small,
      ),
    ],
    RequestSubmissionConflictCode.noCoverage => [
      SizedBox(height: AppSpacing.md),
      AppButton(
        label: 'client_requests.conflict_no_coverage_cta'.tr(),
        onPressed: onChangeLocation,
        variant: AppButtonVariant.secondary,
        size: AppButtonSize.small,
      ),
    ],
    RequestSubmissionConflictCode.outsideHours => [
      if (conflict.hasAlternatives) ...[
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final alternative in conflict.alternatives)
              AppChip(
                label: _alternativeLabel(context, alternative),
                // One tap adopts the window and re-submits, which is the whole
                // point of the server sending them.
                onTap: () => onPickAlternative(alternative.start),
              ),
          ],
        ),
      ],
    ],
    RequestSubmissionConflictCode.unknown => const [],
  };

  String _alternativeLabel(
    BuildContext context,
    RequestSubmissionAlternative alternative,
  ) {
    final start = formatRequestDateTime(context, alternative.start);
    final end = alternative.end;
    return end == null ? start : '$start – ${formatRequestTime(context, end)}';
  }
}
