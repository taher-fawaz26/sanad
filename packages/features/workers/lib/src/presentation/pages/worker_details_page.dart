import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/domain/usecases/get_worker_usecase.dart';
import 'package:workers/src/routes/worker_routes.dart';

const _avatarSize = 96.0;
const _statusDotSize = 24.0;
const _cardRadius = 16.0;

/// Figma `worker-details` (`1526:11216`).
///
/// Receives [initialWorker] when navigated from the list (instant render),
/// and falls back to fetching by [workerId] for deep-links / refresh.
class WorkerDetailsPage extends StatefulWidget {
  const WorkerDetailsPage({
    required this.workerId,
    this.initialWorker,
    super.key,
  });

  final String workerId;
  final WorkerEntity? initialWorker;

  @override
  State<WorkerDetailsPage> createState() => _WorkerDetailsPageState();
}

class _WorkerDetailsPageState extends State<WorkerDetailsPage> {
  WorkerEntity? _worker;
  Failure? _failure;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _worker = widget.initialWorker;
    if (_worker == null) _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    final result = await sl<GetWorkerUseCase>()
        .call(GetWorkerParams(widget.workerId))
        .run();
    if (!mounted) return;
    result.match(
      (failure) => setState(() {
        _failure = failure;
        _loading = false;
      }),
      (worker) => setState(() {
        _worker = worker;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final worker = _worker;

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
              child: switch ((worker, _loading, _failure)) {
                (final WorkerEntity w, _, _) => _DetailsBody(worker: w),
                (_, true, _) => const Center(child: AppLoadingIndicator()),
                (_, _, final Failure failure) => _errorState(failure),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(Failure failure) {
    final display = failureErrorDisplay(failure);
    return AppErrorState(
      style: display.isConnectivity
          ? AppErrorStateStyle.network
          : AppErrorStateStyle.generic,
      title: display.title,
      description: display.description,
      retryLabel: failureRetryLabel(),
      onRetry: display.isRetryable ? _fetch : null,
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.worker});

  final WorkerEntity worker;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          width: responsiveDimension(_avatarSize),
          height: responsiveDimension(_avatarSize),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: _AvatarImage(
                  url: worker.profilePicUrl,
                  size: responsiveDimension(_avatarSize),
                ),
              ),
              if (worker.status == WorkerStatus.active)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: responsiveDimension(
                      _statusDotSize,
                    ),
                    height: responsiveDimension(
                      _statusDotSize,
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

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Image.asset(
      AppImages.addWorkers,
      package: AppAssets.package,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );

    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) return placeholder;

    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
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
      if (worker.assignedBranches.isNotEmpty)
        _ContactDetailRow(
          label: 'workers.contact_branches'.tr(),
          value: worker.assignedBranches.map((b) => b.branchName).join(', '),
          labelColor: colors.textSecondary,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: dark.shade50,
        borderRadius: BorderRadius.circular(
          responsiveDimension(_cardRadius),
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
