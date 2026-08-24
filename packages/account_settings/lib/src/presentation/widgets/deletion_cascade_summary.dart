import 'package:account_settings/src/domain/entities/deletion_cascade_preview.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Every affected count from the live cascade preview — branches, services,
/// team accounts, invitations, documents, media, unassigned branches, and
/// any additional field the backend returns. Never truncated to "and N
/// more": this widget renders inside the page's own scroll view, so however
/// many rows there are, they are all reachable.
class DeletionCascadeSummary extends StatelessWidget {
  const DeletionCascadeSummary({required this.cascade, super.key});

  final DeletionCascadePreview cascade;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, int)>[
      ('account_deletion.cascade_branches'.tr(), cascade.branches),
      ('account_deletion.cascade_services'.tr(), cascade.services),
      ('account_deletion.cascade_team_accounts'.tr(), cascade.teamAccounts),
      ('account_deletion.cascade_invitations'.tr(), cascade.invitations),
      ('account_deletion.cascade_documents'.tr(), cascade.documents),
      ('account_deletion.cascade_media'.tr(), cascade.media),
      if (cascade.branchesUnassigned > 0)
        (
          'account_deletion.cascade_branches_unassigned'.tr(),
          cascade.branchesUnassigned,
        ),
      for (final entry in cascade.extraCounts.entries) (entry.key, entry.value),
    ];

    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'account_deletion.cascade_title'.tr(),
          style: typography.regularNormal.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        for (final (label, count) in rows) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: typography.regularNormal.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: typography.regularNormal.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
