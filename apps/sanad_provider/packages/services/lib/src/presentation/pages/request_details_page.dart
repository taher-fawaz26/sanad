import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';

/// Service Request detail screen — Figma `4715:24988` (under review),
/// `4715:25178` (rejected), `4715:25265` (approved). Visual state adapts to
/// [ServiceRequestEntity.status].
///
/// Reuses the same entity already loaded by `ServiceRequestsListBloc` — no
/// new fetch. The Figma frames also show a "Unified Request No." (e.g.
/// `REQ-MD-88390`); `ServiceRequestEntity` has no such formatted-number
/// field, so it's intentionally omitted here rather than fabricated (see
/// audit blockers).
class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({required this.request, super.key});

  final ServiceRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavBar(
              title: 'services.request_details.title'.tr(),
              showBackButton: true,
              onLeadingTap: () {
                if (context.canPop()) context.pop();
              },
              trailing: AppNotificationIcon(hasUnread: true, onTap: () {}),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(AppSpacing.xl),
                children: [
                  Text(
                    'services.title'.tr(),
                    style: context.appTypography
                        .bold(context.appTypography.title2)
                        .copyWith(color: colors.textPrimary),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _RequestDetailsCard(request: request),
                  SizedBox(height: AppSpacing.lg),
                  _InfoSection(request: request),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Kept locale-independent (English month names) rather than pulling in
/// `intl` for a single date field — `services` doesn't otherwise depend on
/// it.
String _formatDate(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

class _RequestDetailsCard extends StatelessWidget {
  const _RequestDetailsCard({required this.request});

  final ServiceRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: colors.palettes.sky.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'services.request_details.request_details'.tr(),
                  style: typography
                      .semiBold(typography.regularNormal)
                      .copyWith(color: colors.textPrimary),
                ),
              ),
              AppStatusBadge(
                label: _statusLabel(request.status),
                type: _statusType(request.status),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          _MetaRow(
            icon: Icons.calendar_today_outlined,
            label: 'services.request_details.submitted_date'.tr(),
            value: _formatDate(request.createdAt),
          ),
          if (request.status == ServiceRequestStatus.pending) ...[
            SizedBox(height: AppSpacing.lg),
            AppAlert(
              type: AppAlertType.warning,
              message: 'services.request_details.awaiting_assignment'.tr(),
            ),
          ],
          if (request.status == ServiceRequestStatus.rejected &&
              (request.rejectionReason ?? '').isNotEmpty) ...[
            SizedBox(height: AppSpacing.lg),
            AppAlert(
              type: AppAlertType.rejected,
              message: request.rejectionReason!,
            ),
          ],
          if (request.status == ServiceRequestStatus.approved) ...[
            SizedBox(height: AppSpacing.lg),
            _AcceptedBanner(),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(ServiceRequestStatus status) => switch (status) {
    ServiceRequestStatus.pending => 'services.request_status_pending'.tr(),
    ServiceRequestStatus.approved => 'services.request_status_approved'.tr(),
    ServiceRequestStatus.rejected => 'services.request_status_rejected'.tr(),
  };

  static AppStatusBadgeType _statusType(ServiceRequestStatus status) =>
      switch (status) {
        ServiceRequestStatus.pending => AppStatusBadgeType.warning,
        ServiceRequestStatus.approved => AppStatusBadgeType.success,
        ServiceRequestStatus.rejected => AppStatusBadgeType.alert,
      };
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.textSecondary),
        SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: typography.smallNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: typography
                  .semiBold(typography.regularNormal)
                  .copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}

/// Figma's green "Your request has been accepted" row — [AppAlert] has no
/// success/green variant, so this reuses `colors.success`/`successContainer`
/// directly rather than shoehorning it into an unrelated alert type.
class _AcceptedBanner extends StatelessWidget {
  const _AcceptedBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.successContainer,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: colors.success),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'services.request_details.accepted_banner'.tr(),
              style: typography.smallNormal.copyWith(color: colors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.request});

  final ServiceRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final categoryName =
        request.resultingCategory?.name ?? request.requestedCategoryName;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: colors.palettes.sky.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: 'services.request_details.service_name'.tr(),
            value: request.displayName,
          ),
          if (categoryName != null && categoryName.isNotEmpty) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: colors.palettes.sky.shade200,
            ),
            _InfoRow(
              label: 'services.request_details.category'.tr(),
              value: categoryName,
            ),
          ],
          Divider(height: 1, thickness: 1, color: colors.palettes.sky.shade200),
          _InfoRow(
            label: 'services.request_details.description'.tr(),
            value: request.description,
          ),
          if (request.media.isNotEmpty) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: colors.palettes.sky.shade200,
            ),
            Text(
              'services.request_details.images'.tr(),
              style: typography.smallNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: responsiveDimension(72),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: request.media.length,
                separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimension.radiusSm),
                  child: Image.network(
                    request.media[index].url,
                    width: responsiveDimension(72),
                    height: responsiveDimension(72),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: typography.smallNormal.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: typography
                .semiBold(typography.regularNormal)
                .copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
