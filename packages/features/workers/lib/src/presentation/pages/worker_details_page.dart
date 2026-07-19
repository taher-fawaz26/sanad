import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';

/// Figma `2. worker-details` (`1526:11216`).
class WorkerDetailsPage extends StatelessWidget {
  const WorkerDetailsPage({required this.worker, super.key});

  final WorkerEntity worker;

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
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    SizedBox(height: AppSpacing.xl),
                    _AvatarHeader(worker: worker),
                    SizedBox(height: AppSpacing.xl),
                    _ContactDetailsCard(worker: worker),
                    SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            _EditProfileButton(),
          ],
        ),
      ),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.worker});

  final WorkerEntity worker;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                worker.initials,
                style: typography.title1.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (worker.status == WorkerStatus.active)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: colors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.white, width: 2),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          worker.fullName,
          style: typography.title2.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          worker.role,
          style: typography.regularNormal.copyWith(color: colors.primary),
          textAlign: TextAlign.center,
        ),
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

    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceVariant),
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'workers.contact_details'.tr(),
            style: typography.regularNormal.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          if (worker.phone != null) ...[
            _DetailRow(
              label: 'workers.contact_phone'.tr(),
              value: worker.phone!,
            ),
            SizedBox(height: AppSpacing.md),
          ],
          if (worker.email != null) ...[
            _DetailRow(
              label: 'workers.contact_email'.tr(),
              value: worker.email!,
            ),
            SizedBox(height: AppSpacing.md),
          ],
          _DetailRow(
            label: 'workers.contact_type'.tr(),
            value: worker.role,
          ),
          if (worker.branches != null) ...[
            SizedBox(height: AppSpacing.md),
            _DetailRow(
              label: 'workers.contact_branches'.tr(),
              value: worker.branches!,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      children: [
        Text(
          label,
          style: typography.smallNormal.copyWith(color: colors.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: typography.smallNormal.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: AppButton(
        label: 'workers.edit_profile'.tr(),
        onPressed: () => showAppSnackbar(
          context: context,
          title: 'workers.coming_soon'.tr(),
        ),
      ),
    );
  }
}
