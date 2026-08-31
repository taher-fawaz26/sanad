import 'dart:async';

import 'package:activity_logs/activity_logs.dart';
import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/domain/usecases/get_worker_usecase.dart';
import 'package:workers/src/presentation/bloc/worker_action/worker_action_cubit.dart';
import 'package:workers/src/presentation/services/worker_branch_assigner.dart';
import 'package:workers/src/presentation/services/worker_role_assigner.dart';
import 'package:workers/src/presentation/utils/worker_action_copy.dart';
import 'package:workers/src/presentation/utils/worker_type_localization.dart';
import 'package:workers/src/presentation/widgets/worker_actions_bottom_sheet.dart';
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

/// Pop result signaling the viewed worker was deleted from within the
/// details page's own "more actions" sheet — distinguishes "removed" from
/// "replaced" (a plain [WorkerEntity] result) for `WorkerListItem`'s caller.
class WorkerDeletedResult {
  const WorkerDeletedResult(this.workerId);

  final String workerId;
}

/// Figma `worker-details` (`1526:11216`).
///
/// Receives [initialWorker] when navigated from the list (instant render),
/// and falls back to fetching by [workerId] for deep-links / refresh.
class WorkerDetailsPage extends StatefulWidget {
  const WorkerDetailsPage({
    required this.workerId,
    required this.isOwner,
    required this.canViewActivity,
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

  /// Whether the signed-in account may see this worker's "Recent Activity"
  /// section (owner/manager only — `actorId` is silently ignored for a
  /// worker token, so a plain worker viewing this page would otherwise see
  /// *their own* feed rendered under someone else's profile).
  final bool canViewActivity;

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

  /// Set once a delete from this page's own "more actions" sheet succeeds —
  /// takes over [_popResult] so the list removes the worker instead of
  /// (harmlessly, but incorrectly) re-adding a now-deleted one.
  bool _deleted = false;

  StreamSubscription<WorkerActionEffect>? _actionEffectSub;

  void _applyUpdatedWorker(WorkerEntity worker) {
    setState(() {
      _worker = worker;
      _didUpdate = true;
    });
  }

  Object? get _popResult {
    if (_deleted) return WorkerDeletedResult(widget.workerId);
    return _didUpdate ? _worker : null;
  }

  @override
  void initState() {
    super.initState();
    _worker = widget.initialWorker;
    if (_worker == null) _fetch();
    // Suspend/Delete are owner-only (RBAC Phase 7 finding G3 — no
    // permission exists for either `PATCH /workers/:id/status` or `DELETE
    // /workers/:id`), matching the swipe actions' and Edit profile's own
    // gating — so the cubit is only read for an owner, who is the only
    // account this route ever provides one for (see `workers_module.dart`).
    if (widget.isOwner) {
      _actionEffectSub = context.read<WorkerActionCubit>().effects.listen(
        _onActionEffect,
      );
    }
  }

  @override
  void dispose() {
    _actionEffectSub?.cancel();
    super.dispose();
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

  void _onActionEffect(WorkerActionEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case WorkerActionStarted(:final type):
        AppProgress.show(context, title: workerActionProgressTitle(type));
      case WorkerActionSucceeded(:final type, :final updatedWorker):
        AppProgress.dismiss();
        showAppSnackbar(
          context: context,
          title: workerActionSuccessMessage(type),
        );
        if (type == WorkerActionType.delete) {
          setState(() => _deleted = true);
          Navigator.of(context).pop(_popResult);
        } else if (updatedWorker != null) {
          _applyUpdatedWorker(updatedWorker);
        }
      case WorkerActionFailed(:final type, :final failure):
        AppProgress.dismiss();
        showAppErrorSnackbar(
          context: context,
          title: workerActionFailureMessage(type, failure),
        );
    }
  }

  void _showMoreActions(BuildContext context) {
    final worker = _worker;
    if (worker == null) return;
    showWorkerActionsBottomSheet(context: context, worker: worker);
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
                trailingAction: widget.isOwner && worker != null
                    ? AppNavBarTrailingAction.icon
                    : AppNavBarTrailingAction.none,
                trailing: Icon(Icons.more_vert, color: colors.textPrimary),
                onTrailingTap: widget.isOwner && worker != null
                    ? () => _showMoreActions(context)
                    : null,
              ),
              Expanded(
                child: switch ((worker, _loading, _failure)) {
                  (final WorkerEntity w, _, _) => _DetailsBody(
                    worker: w,
                    isOwner: widget.isOwner,
                    canViewActivity: widget.canViewActivity,
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
    required this.canViewActivity,
    required this.onWorkerUpdated,
  });

  final WorkerEntity worker;
  final bool isOwner;
  final bool canViewActivity;
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
                // Another worker's activity is owner/manager-only — see
                // `WorkerDetailsPage.canViewActivity`.
                if (canViewActivity) ...[
                  SizedBox(height: AppSpacing.lg),
                  WorkerRecentActivitySection(workerId: worker.id),
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
    final typeLabel = WorkerType.fromApiString(worker.role).localizedLabel();

    final rows = <_ContactDetailRow>[
      _ContactDetailRow(
        label: 'workers.contact_phone'.tr(),
        value: _displayValue(worker.phone),
        isLtr: true,
      ),
      _ContactDetailRow(
        label: 'workers.contact_email'.tr(),
        value: _displayValue(worker.email),
        isLtr: true,
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
    this.isLtr = false,
  });

  final String label;
  final String value;

  /// Whether [value] is inherently left-to-right (phone, email). Such values
  /// are wrapped in a Unicode LTR isolate so a leading `+` or digits read at
  /// the visual start even under an RTL (Arabic) layout, and are capped to a
  /// single line so a long email doesn't wrap awkwardly. See SAN-771.
  final bool isLtr;

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
        SizedBox(width: AppSpacing.md),
        // The value takes all remaining width so a long value (email) reads on
        // one line instead of wrapping. LTR values are isolated + single-line.
        Expanded(
          child: Text(
            isLtr ? value.ltrIsolated : value,
            style: typography.smallNormal.copyWith(
              color: colors.textPrimary,
              height: 16 / 14,
            ),
            textAlign: TextAlign.end,
            maxLines: isLtr ? 1 : null,
            overflow: isLtr ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }
}
