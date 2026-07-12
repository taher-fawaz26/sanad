import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/presentation/widgets/branch_empty_states.dart';
import 'package:branches/src/routes/branch_routes.dart';
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
    return BlocBuilder<BranchesBloc, BranchesState>(
      builder: (context, state) {
        if (state.isLoading && state.branches.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final branches = state.filteredBranches;
        final totalCount = state.branches.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSection(
              title: 'branches.count_label'.tr(),
              size: AppSectionSize.compact,
              trailing: AppSectionTrailing.custom,
              trailingWidget: AppNotificationBadge(count: totalCount),
            ),
            SizedBox(height: AppSpacing.xs),
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
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: AppSearchField(
                hint: 'branches.search_hint'.tr(),
                showMicIcon: false, // hide mic by default for branch search
                onChanged: (value) => context
                    .read<BranchesBloc>()
                    .add(BranchesSearchChangedEvent(value)),
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
            Expanded(
              child: state.hasError && state.branches.isEmpty
                  ? _ErrorState(
                      onRetry: () => context
                          .read<BranchesBloc>()
                          .add(const BranchesRefreshEvent()),
                    )
                  : branches.isEmpty
                      ? _EmptyState(
                          searchQuery: state.searchQuery,
                          onClearSearch: () => context
                              .read<BranchesBloc>()
                              .add(const BranchesSearchChangedEvent('')),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(bottom: AppSpacing.lg),
                          itemCount: branches.length,
                          itemBuilder: (context, index) =>
                              _BranchListItem(branch: branches[index]),
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.currentFilter});

  final BranchFilter currentFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'branches.filter_all'.tr(),
            size: AppButtonSize.small,
            type: currentFilter == BranchFilter.all
                ? AppButtonType.secondary
                : AppButtonType.outline,
            onPressed: () => context
                .read<BranchesBloc>()
                .add(const BranchesFilterChangedEvent(BranchFilter.all)),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppButton(
            label: 'branches.filter_maintenance'.tr(),
            size: AppButtonSize.small,
            type: currentFilter == BranchFilter.maintenance
                ? AppButtonType.secondary
                : AppButtonType.outline,
            onPressed: () => context
                .read<BranchesBloc>()
                .add(
                  const BranchesFilterChangedEvent(BranchFilter.maintenance),
                ),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppButton(
            label: 'branches.filter_active'.tr(),
            size: AppButtonSize.small,
            type: currentFilter == BranchFilter.active
                ? AppButtonType.secondary
                : AppButtonType.outline,
            onPressed: () => context
                .read<BranchesBloc>()
                .add(
                  const BranchesFilterChangedEvent(BranchFilter.active),
                ),
          ),
        ),
      ],
    );
  }
}

class _BranchListItem extends StatelessWidget {
  const _BranchListItem({required this.branch});

  final BranchEntity branch;

  @override
  Widget build(BuildContext context) {
    final initial =
        branch.branchName.isNotEmpty ? branch.branchName[0].toUpperCase() : '?';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: AppListCard(
        title: branch.branchName,
        caption: branch.displayAddress,
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
            size: AppIconButtonSize.small,
            iconColor: context.appColors.textPrimary,
            onTap: () {},
          ),
        ),
        onTap: () {},
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searchQuery, this.onClearSearch});

  final String searchQuery;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    if (searchQuery.trim().isNotEmpty) {
      return Center(
        child: BranchesSearchEmptyState(
          query: searchQuery.trim(),
          onClearSearch: onClearSearch,
        ),
      );
    }
    return Center(
      child: AppGenericEmptyState(
        title: 'branches.empty_first_branch_title'.tr(),
        description: 'branches.empty_first_branch_description'.tr(),
        actionLabel: 'branches.empty_first_branch_action'.tr(),
        onAction: () => context.push(BranchRoutes.add),
        actionIcon: const Icon(Icons.add_circle_outline),
        actionIconPosition: AppButtonIconPosition.center,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppGenericEmptyState(
        title: 'empty_states.network_title'.tr(),
        description: 'empty_states.network_description'.tr(),
        actionLabel: 'empty_states.retry'.tr(),
        onAction: onRetry,
      ),
    );
  }
}
