import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/branch_details/branch_details_bloc.dart';
import 'package:branches/src/presentation/utils/branch_maps_launcher.dart';
import 'package:branches/src/presentation/widgets/branch_summary_content.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Figma branch details / review layout (`365:14892`).
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
        showAppSnackbar(
          context: context,
          title:
              state.statusUpdateFailure?.message ??
              'branches.details.status_update_error'.tr(),
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
    final retryLabel = 'empty_states.retry'.tr();
    final f = failure;

    if (f is NoInternetFailure || f is NetworkFailure) {
      return AppNetworkFailureState(
        title: 'empty_states.network_title'.tr(),
        description: 'empty_states.network_description'.tr(),
        retryLabel: retryLabel,
        onRetry: onRetry,
      );
    }

    if (f is TimeoutFailure) {
      return AppNetworkFailureState(
        title: 'empty_states.timeout_title'.tr(),
        description: 'empty_states.timeout_description'.tr(),
        retryLabel: retryLabel,
        onRetry: onRetry,
      );
    }

    final description = (f != null && f.message.isNotEmpty)
        ? f.message.tr()
        : 'empty_states.server_error_description'.tr();

    return AppGenericEmptyState(
      title: 'empty_states.server_error_title'.tr(),
      description: description,
      actionLabel: retryLabel,
      onAction: onRetry,
    );
  }
}

class _BranchDetailsContent extends StatelessWidget {
  const _BranchDetailsContent({required this.branch});

  final BranchEntity branch;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final model = BranchSummaryViewModel.fromEntity(
      branch: branch,
      closedScheduleColor: colors.error,
      onOpenMaps: () => _openMaps(context),
      onViewAllServices: branch.serviceNames != null &&
              branch.serviceNames!.length >
                  BranchSummaryContent.visibleServiceCount
          ? () => _showComingSoon(context)
          : null,
      onViewAllTeam: branch.workers.isNotEmpty
          ? () => _showComingSoon(context)
          : null,
    );

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
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: BranchSummaryContent(model: model),
              ),
            ),
            AppBottomActionBar(
              child: AppButton(
                label: 'branches.details.edit_branch'.tr(),
                onPressed: () => _showComingSoon(
                  context,
                  'branches.details.edit_coming_soon'.tr(),
                ),
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
            _showComingSoon(
              context,
              'branches.details.edit_coming_soon'.tr(),
            );
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

  void _showComingSoon(BuildContext context, [String? message]) {
    showAppSnackbar(
      context: context,
      title: message ?? 'branches.details.edit_coming_soon'.tr(),
    );
  }
}
