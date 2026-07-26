import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/branch_details/branch_details_bloc.dart';
import 'package:branches/src/presentation/utils/branch_maps_launcher.dart';
import 'package:branches/src/presentation/widgets/branch_summary_view.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:maps/maps.dart';

/// Figma Branch Details screen (`365:14892`).
///
/// Mirrors the add-branch review layout via [BranchSummaryView], swapping the
/// footer action from "submit" to "Edit branch".
class BranchDetailsPage extends StatelessWidget {
  const BranchDetailsPage({required this.branchId, super.key});

  final String branchId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BranchDetailsBloc, BranchDetailsState>(
      listenWhen: (prev, curr) =>
          prev.statusUpdateFailure != curr.statusUpdateFailure &&
          curr.statusUpdateFailure != null,
      listener: (context, state) {
        final failure = state.statusUpdateFailure;
        showAppErrorSnackbar(
          context: context,
          title: failure != null
              ? failure.localizedMessage()
              : 'branches.details.status_update_error'.tr(),
        );
      },
      builder: (context, state) {
        if (state.isLoading && state.branch == null) {
          return const Scaffold(
            body: Center(child: AppLoadingIndicator()),
          );
        }

        if (state.hasError && state.branch == null) {
          return _BranchDetailsError(
            failure: state.failure,
            onRetry: () => context.read<BranchDetailsBloc>().add(
              const BranchDetailsRefreshEvent(),
            ),
            onClose: () => context.pop(),
          );
        }

        final branch = state.branch;
        if (branch == null) {
          return const SizedBox.shrink();
        }

        return _BranchDetailsContent(branch: branch);
      },
    );
  }
}

class _BranchDetailsError extends StatelessWidget {
  const _BranchDetailsError({
    required this.onRetry,
    required this.onClose,
    this.failure,
  });

  final Failure? failure;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            AppNavBar(
              title: '',
              leading: AppCloseIcon(onTap: onClose),
            ),
            Expanded(
              child: Center(child: _errorContent()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorContent() {
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

class _BranchDetailsContent extends StatelessWidget {
  const _BranchDetailsContent({required this.branch});

  final BranchEntity branch;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final managerCaption = branch.branchManagerName == null
        ? null
        : 'branches.details.manager_caption'.tr(
            namedArgs: {'name': branch.branchManagerName!},
          );
    final position = (branch.lat != null && branch.lng != null)
        ? LatLng(branch.lat!, branch.lng!)
        : null;
    final areaNames = (branch.servingAreaNames?.isNotEmpty ?? false)
        ? branch.servingAreaNames!
        : (branch.servingAreaPlaceIds ?? const <String>[]);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavBar(
              title: '',
              leading: AppCloseIcon(onTap: () => context.pop()),
              trailingAction: AppNavBarTrailingAction.icon,
              trailing: Icon(
                Icons.more_vert,
                size: 24,
                color: colors.textPrimary,
              ),
              onTrailingTap: () => _showMoreActions(context),
            ),
            Expanded(
              child: BranchSummaryView(
                data: BranchSummaryData(
                  title: branch.branchName,
                  caption: managerCaption ?? branch.displayAddress,
                  badgeLabel: branch.isAvailable
                      ? 'branches.status_active'.tr()
                      : 'branches.status_maintenance'.tr(),
                  badgeType: branch.isAvailable
                      ? AppStatusBadgeType.success
                      : AppStatusBadgeType.warning,
                  position: position,
                  address: branch.displayAddress,
                  phone: branch.branchPhone,
                  managerName: branch.branchManagerName,
                  isCustomSchedule:
                      branch.availabilityMode == BranchAvailabilityMode.custom,
                  schedule: branch.availability ?? const [],
                  areaNames: areaNames,
                  serviceNames: branch.serviceNames ?? const [],
                  workerInitials: [
                    for (final worker in branch.workers) worker.initials,
                  ],
                ),
                onOpenMaps: () => _openMaps(context),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: AppButton(
                label: 'branches.details.edit_branch'.tr(),
                onPressed: () => _openEdit(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final opened = await BranchMapsLauncher.openBranchLocation(branch);
    if (!context.mounted) return;
    if (!opened) {
      showAppSnackbar(
        context: context,
        title: 'branches.details.maps_unavailable'.tr(),
      );
    }
  }

  /// Opens the shared wizard in edit mode, passing the already-loaded branch so
  /// it prefills without a refetch. Refreshes details when a save succeeds.
  Future<void> _openEdit(BuildContext context) async {
    final bloc = context.read<BranchDetailsBloc>();
    final saved = await context.push<bool>(
      BranchRoutes.editFor(branch.id),
      extra: branch,
    );
    if (saved ?? false) {
      bloc.add(const BranchDetailsRefreshEvent());
    }
  }

  void _showMoreActions(BuildContext context) {
    final isActive = branch.isAvailable;
    final bloc = context.read<BranchDetailsBloc>();
    showAppActionSheet<void>(
      context: context,
      items: [
        AppActionSheetItem(
          label: isActive
              ? 'branches.details.action_set_maintenance'.tr()
              : 'branches.details.action_set_active'.tr(),
          leading: Icon(
            isActive ? Icons.pause_circle_outline : Icons.check_circle_outline,
          ),
          onTap: () {
            Navigator.of(context).pop();
            bloc.add(BranchStatusToggleEvent(isAvailable: !isActive));
          },
        ),
        AppActionSheetItem(
          label: 'branches.details.action_edit'.tr(),
          leading: const Icon(Icons.edit_outlined),
          onTap: () {
            Navigator.of(context).pop();
            _openEdit(context);
          },
        ),
        AppActionSheetItem(
          label: 'branches.details.action_delete'.tr(),
          leading: const Icon(Icons.delete_outline),
          isDestructive: true,
          onTap: () {
            Navigator.of(context).pop();
            _showComingSoon(
              context,
              'branches.details.delete_coming_soon'.tr(),
            );
          },
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    showAppSnackbar(context: context, title: message);
  }
}
