import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/presentation/utils/branch_type_label.dart';
import 'package:branches/src/presentation/widgets/branch_actions_bottom_sheet.dart';
import 'package:branches/src/presentation/widgets/branch_empty_states.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Figma Branches screen (`73:2902`).
class ProviderBranchesPage extends StatefulWidget {
  const ProviderBranchesPage({super.key});

  @override
  State<ProviderBranchesPage> createState() => _ProviderBranchesPageState();
}

class _ProviderBranchesPageState extends State<ProviderBranchesPage> {
  int _segmentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<BranchesBloc>().add(const BranchesFetchEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTableRow(
              title: 'branches.company_name'.tr(),
              trailing: AppTableTrailing.icon,
              leading: AppTableLeading.avatar,
              leadingAvatar: AppAvatar(
                initials: 'G',
                backgroundColor: context.appColors.primary,
                showStatusDot: true,
              ),
              trailingIcon: AppNotificationIcon(
                hasUnread: true,
                onTap: () {},
              ),
            ),
            AppSection(
              title: 'branches.title'.tr(),
              caption: 'branches.subtitle'.tr(),
              size: AppSectionSize.large,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: AppSegmentedControl(
                segments: [
                  'branches.tab_branches'.tr(),
                  'branches.tab_company_profile'.tr(),
                ],
                selectedIndex: _segmentIndex,
                onChanged: (index) => setState(() => _segmentIndex = index),
              ),
            ),
            Expanded(
              child: _segmentIndex == 0
                  ? _BranchesTab()
                  : _CompanyProfilePlaceholder(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyProfilePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'branches.company_profile_placeholder'.tr(),
        style: context.appTypography.regularNormal.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
    );
  }
}

class _BranchesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<BranchesBloc, BranchesState>(
      listenWhen: (previous, current) =>
          previous.actionFailure != current.actionFailure &&
          current.actionFailure != null,
      listener: (context, state) {
        final message = state.actionFailure!.message.trim();
        final title = message.isEmpty
            ? 'branches.actions.action_failed'.tr()
            : message.contains(' ')
            ? message
            : message.tr();
        showAppSnackbar(context: context, title: title);
        context.read<BranchesBloc>().add(
          const BranchActionFailureClearedEvent(),
        );
      },
      child: BlocBuilder<BranchesBloc, BranchesState>(
        builder: (context, state) {
          if (state.isLoading && state.branches.isEmpty) {
            return const Center(child: AppLoadingIndicator());
          }

          final branches = state.filteredBranches;
          final totalCount = state.branches.length;
          final isZeroBranches = totalCount == 0 && state.isSuccess;

          return ColoredBox(
            color: isZeroBranches
                ? context.appColors.palettes.sky.shade50
                : context.appColors.surface,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isZeroBranches) ...[
                AppSection(
                  title: 'branches.count_label'.tr(),
                  size: AppSectionSize.compact,
                  trailing: AppSectionTrailing.custom,
                  trailingWidget: AppNotificationBadge(count: totalCount),
                ),
                SizedBox(height: AppSpacing.xs),
              ],
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: AppButton(
                  label: 'branches.add_button'.tr(),
                  icon: const Icon(Icons.add_circle_outline),
                  iconPosition: AppButtonIconPosition.center,
                  onPressed: () => context.push(BranchRoutes.add),
                ),
              ),
              if (!isZeroBranches) ...[
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: AppSearchField(
                    hint: 'branches.search_hint'.tr(),
                    showMicIcon: false,
                    showClearWhenFilled: true,
                    onChanged: (value) => context.read<BranchesBloc>().add(
                      BranchesSearchChangedEvent(value),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: _FilterRow(currentFilter: state.filter),
                ),
                SizedBox(height: AppSpacing.sm),
              ],
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () async {
                    context.read<BranchesBloc>().add(
                      const BranchesRefreshEvent(),
                    );
                  },
                  child: state.hasError && state.branches.isEmpty
                      ? AppFillRemainingScrollable(
                          child: _ErrorState(
                            failure: state.failure,
                            onRetry: () => context.read<BranchesBloc>().add(
                              const BranchesRefreshEvent(),
                            ),
                          ),
                        )
                      : branches.isEmpty
                      ? AppFillRemainingScrollable(
                          child: _EmptyState(
                            totalCount: totalCount,
                            searchQuery: state.searchQuery,
                            filter: state.filter,
                            onClearSearch: () =>
                                context.read<BranchesBloc>().add(
                                  const BranchesSearchChangedEvent(''),
                                ),
                            onClearFilter: () => context.read<BranchesBloc>().add(
                              const BranchesFilterChangedEvent(
                                BranchFilter.all,
                              ),
                            ),
                            onAddBranch: () => context.push(BranchRoutes.add),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(bottom: AppSpacing.lg),
                          itemCount: branches.length,
                          itemBuilder: (context, index) =>
                              _BranchListItem(branch: branches[index]),
                        ),
                ),
              ),
            ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.currentFilter});

  final BranchFilter currentFilter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'branches.filter_all'.tr(),
            selected: currentFilter == BranchFilter.all,
            onTap: () => context.read<BranchesBloc>().add(
              const BranchesFilterChangedEvent(BranchFilter.all),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'branches.filter_maintenance'.tr(),
            selected: currentFilter == BranchFilter.maintenance,
            onTap: () => context.read<BranchesBloc>().add(
              const BranchesFilterChangedEvent(BranchFilter.maintenance),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'branches.filter_active'.tr(),
            selected: currentFilter == BranchFilter.active,
            onTap: () => context.read<BranchesBloc>().add(
              const BranchesFilterChangedEvent(BranchFilter.active),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      selected: selected,
      style: selected ? AppChipStyle.solid : AppChipStyle.outline,
      onTap: onTap,
    );
  }
}

class _BranchListItem extends StatelessWidget {
  const _BranchListItem({required this.branch});

  final BranchEntity branch;

  @override
  Widget build(BuildContext context) {
    final initial = branch.branchName.isNotEmpty
        ? branch.branchName[0].toUpperCase()
        : '?';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: AppListCard(
        title: branch.branchName,
        caption: branchTypeLabel(branch.branchType),
        leading: AppAvatar(
          initials: initial,
          backgroundColor: context.appColors.primary,
          showStatusDot: true,
        ),
        badge: AppStatusBadge(
          label: branch.isAvailable
              ? 'branches.status_active'.tr()
              : 'branches.status_maintenance'.tr(),
          type: branch.isAvailable
              ? AppStatusBadgeType.success
              : AppStatusBadgeType.warning,
          size: AppStatusBadgeSize.compact,
        ),
        trailing: Semantics(
          label: 'branches.more_actions'.tr(),
          child: AppIconButton(
            icon: Icons.more_vert,
            iconColor: context.appColors.textPrimary,
            onTap: () => showBranchActionsBottomSheet(
              context: context,
              branch: branch,
            ),
          ),
        ),
        onTap: () => context.push(BranchRoutes.detailsFor(branch.id)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.totalCount,
    required this.searchQuery,
    required this.filter,
    this.onClearSearch,
    this.onClearFilter,
    this.onAddBranch,
  });

  final int totalCount;
  final String searchQuery;
  final BranchFilter filter;
  final VoidCallback? onClearSearch;
  final VoidCallback? onClearFilter;
  final VoidCallback? onAddBranch;

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) {
      return Center(
        child: BranchesFirstEmptyState(onAddBranch: onAddBranch),
      );
    }

    if (searchQuery.trim().isNotEmpty) {
      return Center(
        child: BranchesSearchEmptyState(
          query: searchQuery.trim(),
          onClearSearch: onClearSearch,
        ),
      );
    }

    if (filter != BranchFilter.all) {
      return Center(
        child: BranchesFilterEmptyState(onClearFilter: onClearFilter),
      );
    }

    return Center(
      child: BranchesFilterEmptyState(onClearFilter: onClearFilter),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, this.failure});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final retryLabel = 'empty_states.retry'.tr();
    final f = failure;

    if (f is NoInternetFailure || f is NetworkFailure) {
      return Center(
        child: AppNetworkFailureState(
          title: 'empty_states.network_title'.tr(),
          description: 'empty_states.network_description'.tr(),
          retryLabel: retryLabel,
          onRetry: onRetry,
        ),
      );
    }

    if (f is TimeoutFailure) {
      return Center(
        child: AppNetworkFailureState(
          title: 'empty_states.timeout_title'.tr(),
          description: 'empty_states.timeout_description'.tr(),
          retryLabel: retryLabel,
          onRetry: onRetry,
        ),
      );
    }

    // ServerFailure, UnknownFailure, or any other mapped failure.
    // Show the actual server message when available so users get
    // meaningful feedback (e.g. "Profile not found. Please start the
    // setup process.") instead of a generic fallback.
    final description = (f != null && f.message.isNotEmpty)
        ? f.message.tr()
        : 'empty_states.server_error_description'.tr();

    return Center(
      child: AppGenericEmptyState(
        title: 'empty_states.server_error_title'.tr(),
        description: description,
        actionLabel: retryLabel,
        onAction: onRetry,
      ),
    );
  }
}
