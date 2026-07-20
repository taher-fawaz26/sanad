import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/routes/worker_routes.dart';

/// Figma `worker-details` (`1526:11216`).
class WorkerDetailsPage extends StatelessWidget {
  const WorkerDetailsPage({required this.worker, super.key});

  final WorkerEntity worker;

  static const _avatarSize = 96.0;
  static const _statusDotSize = 24.0;
  static const _cardRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavBar(
              title: 'workers.details_title'.tr(),
              showBackButton: true,
              trailing: AppNotificationIcon(onTap: () {}),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    _ProfileHeader(worker: worker),
                    SizedBox(height: AppSpacing.xxl),
                    _ContactDetailsCard(worker: worker),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.sm,
              ),
              child: AppButton(
                label: 'workers.edit_profile'.tr(),
                onPressed: () => context.push(
                  WorkerRoutes.editWorkerFor(worker.id),
                  extra: worker,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.worker});

  final WorkerEntity worker;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final subtitle = worker.jobTitle?.trim();

    return Column(
      children: [
        SizedBox(
          width: responsiveDimension(WorkerDetailsPage._avatarSize),
          height: responsiveDimension(WorkerDetailsPage._avatarSize),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: Image.asset(
                  AppImages.addWorkers,
                  package: AppAssets.package,
                  width: responsiveDimension(WorkerDetailsPage._avatarSize),
                  height: responsiveDimension(WorkerDetailsPage._avatarSize),
                  fit: BoxFit.cover,
                ),
              ),
              if (worker.status == WorkerStatus.active)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: responsiveDimension(
                      WorkerDetailsPage._statusDotSize,
                    ),
                    height: responsiveDimension(
                      WorkerDetailsPage._statusDotSize,
                    ),
                    decoration: BoxDecoration(
                      color: colors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.white,
                        width: responsiveDimension(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          worker.fullName,
          style: typography.title2.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            height: 32 / 24,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: typography.regularNormal.copyWith(
              color: colors.primary,
              height: 24 / 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _ContactDetailsCard extends StatelessWidget {
  const _ContactDetailsCard({required this.worker});

  final WorkerEntity worker;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final dark = colors.palettes.dark;
    final workerType = WorkerType.fromApiString(worker.role);
    final typeLabel = switch (workerType) {
      WorkerType.worker => 'workers.add_worker.type_worker'.tr(),
      WorkerType.manager => 'workers.add_worker.type_manager'.tr(),
    };

    final rows = <_ContactDetailRow>[
      if (worker.phone != null && worker.phone!.isNotEmpty)
        _ContactDetailRow(
          label: 'workers.contact_phone'.tr(),
          value: worker.phone!,
        ),
      if (worker.email != null && worker.email!.isNotEmpty)
        _ContactDetailRow(
          label: 'workers.contact_email'.tr(),
          value: worker.email!,
        ),
      _ContactDetailRow(
        label: 'workers.contact_type'.tr(),
        value: typeLabel,
      ),
      if (worker.jobTitle != null && worker.jobTitle!.trim().isNotEmpty)
        _ContactDetailRow(
          label: 'workers.contact_title'.tr(),
          value: worker.jobTitle!.trim(),
        ),
      if (worker.branches != null && worker.branches!.trim().isNotEmpty)
        _ContactDetailRow(
          label: 'workers.contact_branches'.tr(),
          value: worker.branches!.trim(),
          labelColor: colors.textSecondary,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: dark.shade50,
        borderRadius: BorderRadius.circular(
          responsiveDimension(WorkerDetailsPage._cardRadius),
        ),
        border: Border.all(color: dark.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'workers.contact_details'.tr(),
            style: typography.regularNormal.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 24 / 16,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: AppSpacing.md),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _ContactDetailRow extends StatelessWidget {
  const _ContactDetailRow({
    required this.label,
    required this.value,
    this.labelColor,
  });

  final String label;
  final String value;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: typography.smallNormal.copyWith(
            color: labelColor ?? colors.textMuted,
            height: 16 / 14,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: typography.smallNormal.copyWith(
              color: colors.textPrimary,
              height: 16 / 14,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
