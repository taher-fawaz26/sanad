import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/domain/usecases/get_worker_usecase.dart';
import 'package:workers/src/presentation/services/worker_branch_assigner.dart';
import 'package:workers/src/presentation/services/worker_role_assigner.dart';
import 'package:workers/src/presentation/widgets/worker_error_state.dart';
import 'package:workers/src/routes/worker_routes.dart';

/// Realistic mock used only to skeletonize the profile header + contact +
/// branches cards while the worker loads. The roles card
/// ([WorkerRoleAssigner]) fetches independently by real worker id, so it is
/// intentionally excluded from the skeleton rather than fed a fake id.
final _skeletonWorker = WorkerEntity(
  id: 'skeleton',
  fullName: BoneMock.fullName,
  role: BoneMock.name,
  initials: 'SN',
  jobTitle: BoneMock.words(2),
  phone: BoneMock.phone,
  email: BoneMock.email,
);

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
    required this.isOwner,
    this.initialWorker,
    super.key,
  });

  final String workerId;
  final WorkerEntity? initialWorker;

  /// Whether the signed-in account may see the assigned-roles card and edit
  /// this worker (RBAC Phase 7H). Both back onto owner-only surfaces:
  /// `workers/:id/roles` (assumed owner-only, consistent with every other
  /// RBAC-administration endpoint — no permission exists to delegate role
  /// assignment) and `PATCH /workers/:id` (no update permission exists at
  /// all — RBAC Phase 7 finding G3).
  final bool isOwner;

  @override
  State<WorkerDetailsPage> createState() => _WorkerDetailsPageState();
}

class _WorkerDetailsPageState extends State<WorkerDetailsPage> {
  WorkerEntity? _worker;
  Failure? _failure;
  bool _loading = false;

  /// Tracks whether the worker was updated during this session so the pop
  /// result tells the list to refresh in-place (no refetch).
  bool _didUpdate = false;

  void _applyUpdatedWorker(WorkerEntity worker) {
    setState(() {
      _worker = worker;
      _didUpdate = true;
    });
  }

  WorkerEntity? get _popResult => _didUpdate ? _worker : null;

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

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_popResult);
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavBar(
                title: 'workers.details_title'.tr(),
                showBackButton: true,
                onLeadingTap: () => Navigator.of(context).pop(_popResult),
                trailing: AppNotificationIcon(onTap: () {}),
              ),
              Expanded(
                child: switch ((worker, _loading, _failure)) {
                  (final WorkerEntity w, _, _) => _DetailsBody(
                    worker: w,
                    isOwner: widget.isOwner,
                    onWorkerUpdated: _applyUpdatedWorker,
                  ),
                  (_, true, _) => AppSkeletonizer(
                    enabled: true,
                    child: _DetailsSkeletonBody(worker: _skeletonWorker),
                  ),
                  (_, _, final Failure failure) => WorkerErrorState(
                    failure: failure,
                    onRetry: _fetch,
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.worker,
    required this.isOwner,
    required this.onWorkerUpdated,
  });

  final WorkerEntity worker;
  final bool isOwner;
  final ValueChanged<WorkerEntity> onWorkerUpdated;

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
                // Assigning a worker to branches is owner-only (RBAC Phase
                // 7M — `PATCH /workers/:id` has no update permission,
                // finding G3). The whole card is hidden rather than
                // rendered read-only, matching the audit's "hide unless
                // isOwner" spec for this row.
                if (isOwner) ...[
                  SizedBox(height: AppSpacing.lg),
                  _AssignedBranchesCard(
                    worker: worker,
                    onWorkerUpdated: onWorkerUpdated,
                  ),
                ],
                // RBAC administration is owner-only (RBAC Phase 7H) — no
                // permission exists to delegate assigning a worker's roles.
                if (isOwner && sl.isRegistered<WorkerRoleAssigner>()) ...[
                  SizedBox(height: AppSpacing.lg),
                  sl<WorkerRoleAssigner>().buildRolesCard(worker.id),
                ],
              ],
            ),
          ),
        ),
        // Editing a worker (`PATCH /workers/:id`) is owner-only — no update
        // permission exists (RBAC Phase 7 finding G3) — so the action is
        // hidden entirely for a non-owner rather than left visible to
        // navigate into a route that will bounce them home (RBAC Phase 7E).
        if (isOwner)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.sm,
            ),
            child: AppButton(
              label: 'workers.edit_profile'.tr(),
              onPressed: () async {
                final updated = await context.push<WorkerEntity>(
                  WorkerRoutes.editWorkerFor(worker.id),
                  extra: worker,
                );
                if (updated != null) onWorkerUpdated(updated);
              },
            ),
          ),
      ],
    );
  }
}

/// First-load placeholder for [_DetailsBody] — skeletonizes the profile,
/// contact, and branches cards with mock [worker] data. Omits the roles
/// card ([WorkerRoleAssigner]), which fetches independently by real worker
/// id and would otherwise be fed a fake one.
class _DetailsSkeletonBody extends StatelessWidget {
  const _DetailsSkeletonBody({required this.worker});

  final WorkerEntity worker;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          _ProfileHeader(worker: worker),
          SizedBox(height: AppSpacing.xxl),
          _ContactDetailsCard(worker: worker),
          SizedBox(height: AppSpacing.lg),
          _AssignedBranchesCard(worker: worker, onWorkerUpdated: (_) {}),
        ],
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

    return AppNetworkImage(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorWidget: placeholder,
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
      _ContactDetailRow(
        label: 'workers.contact_phone'.tr(),
        value: _displayValue(worker.phone),
      ),
      _ContactDetailRow(
        label: 'workers.contact_email'.tr(),
        value: _displayValue(worker.email),
      ),
      _ContactDetailRow(
        label: 'workers.contact_type'.tr(),
        value: typeLabel,
      ),
      _ContactDetailRow(
        label: 'workers.contact_title'.tr(),
        value: _displayValue(worker.jobTitle),
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

  String _displayValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '-';
    return trimmed;
  }
}

class _AssignedBranchesCard extends StatelessWidget {
  const _AssignedBranchesCard({
    required this.worker,
    required this.onWorkerUpdated,
  });

  final WorkerEntity worker;
  final ValueChanged<WorkerEntity> onWorkerUpdated;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final dark = colors.palettes.dark;
    final canAssignBranch =
        WorkerType.fromApiString(worker.role) == WorkerType.worker &&
        worker.assignedBranches.isEmpty;

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
            'workers.assigned_branches_title'.tr(),
            style: typography.regularNormal.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 24 / 16,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          if (worker.assignedBranches.isEmpty)
            canAssignBranch
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          'workers.no_assigned_branches'.tr(),
                          style: typography.smallNormal.copyWith(
                            color: colors.textMuted,
                            height: 16 / 14,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            sl<WorkerBranchAssigner>().showAssignBranchSheet(
                              context: context,
                              worker: worker,
                              onWorkerUpdated: onWorkerUpdated,
                            ),
                        child: Text(
                          'workers.assign_branch'.tr(),
                          style: typography.smallNormal.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                            height: 16 / 14,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    'workers.no_assigned_branches'.tr(),
                    style: typography.smallNormal.copyWith(
                      color: colors.textMuted,
                      height: 16 / 14,
                    ),
                  )
          else
            for (var i = 0; i < worker.assignedBranches.length; i++) ...[
              if (i > 0) SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      worker.assignedBranches[i].branchName,
                      style: typography.smallNormal.copyWith(
                        color: colors.textPrimary,
                        height: 16 / 14,
                      ),
                    ),
                  ),
                ],
              ),
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
  });

  final String label;
  final String value;

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
            color: colors.textMuted,
            height: 16 / 14,
          ),
        ),
        const Spacer(),
        Flexible(
          fit: FlexFit.tight,
          flex: 2,
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
