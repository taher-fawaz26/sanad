import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';
import 'package:services/src/presentation/bloc/request_details/request_details_bloc.dart';
import 'package:services/src/presentation/mappers/service_request_status_ui.dart';
import 'package:services/src/presentation/utils/service_date_format.dart';
import 'package:shared_ui/shared_ui.dart';

/// Service Request detail screen — Figma `4715:24988` (under review),
/// `4715:25178` (rejected), `4715:25265` (approved). Visual state adapts to
/// [ServiceRequestEntity.status].
///
/// Renders [RequestDetailsBloc] state. The bloc is seeded with the list
/// row passed via the route `extra` (which carries the status/dates but not
/// `description`/`rejectionReason`/`images`) and fetches the full detail via
/// `GET /service-requests/:id` on creation.
class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key});

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
              child: BlocBuilder<RequestDetailsBloc, RequestDetailsState>(
                builder: (context, state) => ListView(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  children: [
                    Text(
                      'services.title'.tr(),
                      style: context.appTypography
                          .bold(context.appTypography.title2)
                          .copyWith(color: colors.textPrimary),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _RequestDetailsCard(request: state.request),
                    SizedBox(height: AppSpacing.lg),
                    if (state.status == RequestStatus.failure)
                      _DetailErrorState(
                        failure: state.failure,
                        onRetry: () => context
                            .read<RequestDetailsBloc>()
                            .add(const RequestDetailsFetchRequested()),
                      )
                    else
                      // Skeletonize the *real* info section, seeded with
                      // the partial data already known from the list row,
                      // while the full detail (description/rejection/
                      // images) loads.
                      AppSkeletonizer(
                        enabled: state.isLoading,
                        child: _InfoSection(request: state.request),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.onRetry, this.failure});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final display = failureErrorDisplay(failure);
    return AppErrorState(
      style: display.isConnectivity
          ? AppErrorStateStyle.network
          : AppErrorStateStyle.generic,
      title: display.title,
      description: display.description,
      retryLabel: failureRetryLabel(),
      onRetry: display.isRetryable ? onRetry : null,
    );
  }
}

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
                label: request.status.badgeLabel,
                type: request.status.badgeType,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          _MetaRow(
            icon: Icons.calendar_today_outlined,
            label: 'services.request_details.submitted_date'.tr(),
            value: formatShortDate(request.createdAt),
          ),
          SizedBox(height: AppSpacing.lg),
          _MetaRow(
            icon: Icons.tag_outlined,
            label: 'services.request_details.request_no'.tr(),
            value: request.unifiedRequestId,
          ),
          if (request.status == ServiceRequestStatus.underReview) ...[
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
            value: request.name,
          ),
          Divider(height: 1, thickness: 1, color: colors.palettes.sky.shade200),
          _InfoRow(
            label: 'services.request_details.category'.tr(),
            value: request.category.name,
          ),
          if (request.description != null &&
              request.description!.isNotEmpty) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: colors.palettes.sky.shade200,
            ),
            _InfoRow(
              label: 'services.request_details.description'.tr(),
              value: request.description!,
            ),
          ],
          if (request.images.isNotEmpty) ...[
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
                itemCount: request.images.length,
                separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => AppNetworkImage(
                  request.images[index].url,
                  width: responsiveDimension(72),
                  height: responsiveDimension(72),
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(AppDimension.radiusSm),
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
