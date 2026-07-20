import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';

/// Bordered worker row — Figma add-branch workers list (`972:9117`).
///
/// Layout: `[Avatar+dot] [Name + Role] [optional trash]` inside a
/// `dark/50` filled, `dark/200` bordered, 12dp-radius card.
class WorkerListCard extends StatelessWidget {
  const WorkerListCard({
    required this.worker,
    super.key,
    this.onTap,
    this.onRemove,
  });

  final WorkerEntity worker;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final dark = colors.palettes.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: dark.shade50,
          borderRadius: BorderRadius.circular(AppDimension.radiusMd),
          border: Border.all(color: dark.shade200),
        ),
        child: Row(
          children: [
            AppAvatar(
              initials: worker.initials,
              backgroundColor: colors.primary,
              showStatusDot: true,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography
                        .medium(typography.regularTight)
                        .copyWith(
                          color: colors.textPrimary,
                        ),
                  ),
                  SizedBox(height: responsiveDimension(2)),
                  Text(
                    (worker.jobTitle?.trim().isNotEmpty ?? false)
                        ? worker.jobTitle!.trim()
                        : worker.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.smallNone.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (onRemove != null) ...[
              SizedBox(width: AppSpacing.md),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: AppSvgPicture.asset(
                    AppSvgs.trash,
                    width: AppDimension.iconMd,
                    height: AppDimension.iconMd,
                    colorFilter: ColorFilter.mode(
                      colors.error,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
