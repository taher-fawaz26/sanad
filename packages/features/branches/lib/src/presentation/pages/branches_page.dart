import 'package:app_assets/app_assets.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/presentation/widgets/branch_empty_states.dart';
import 'package:branches/src/presentation/widgets/branch_list_item.dart';
import 'package:branches/src/presentation/widgets/branch_search_sheet.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Figma Branches screen (`1563:10956`), collapsing header.
///
/// Company row and title collapse away on scroll; search bar stays pinned.
/// Filter chips and branch cards scroll below. "Add Branches" button sits
/// at the bottom of the scrollable content.
class ProviderBranchesPage extends StatefulWidget {
  const ProviderBranchesPage({super.key});

  @override
  State<ProviderBranchesPage> createState() => _ProviderBranchesPageState();
}

class _ProviderBranchesPageState extends State<ProviderBranchesPage> {
  @override
  void initState() {
    super.initState();
    context.read<BranchesBloc>().add(const BranchesFetchEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: const SafeArea(child: _BranchesTab()),
    );
  }
}

class _BranchesTab extends StatelessWidget {
  const _BranchesTab();

  static const _titleSectionHeight = 60.0;
  static const _headerSafetyMargin = 20.0;

  /// Pinned search row: bordered field height + vertical padding around it.
  /// Must match the [PreferredSize] child exactly to avoid RenderFlex overflow.
  double _bottomBarHeight() =>
      responsiveDimension(FieldTokens.fieldHeight) + (AppSpacing.sm * 2);

  double _expandedHeaderHeight() {
    final flexibleSpaceContent =
        AppDimension.tableRowHeight + _titleSectionHeight;
    return flexibleSpaceContent + _bottomBarHeight() + _headerSafetyMargin;
  }

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
          final colors = context.appColors;

          return AppRefreshIndicator(
            onRefresh: () async {
              context.read<BranchesBloc>().add(const BranchesRefreshEvent());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 0,
                  automaticallyImplyLeading: false,
                  backgroundColor: colors.surface,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  elevation: 0,
                  expandedHeight: _expandedHeaderHeight(),
                  flexibleSpace: FlexibleSpaceBar(
                    background: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: _CollapsingHeader(),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(_bottomBarHeight()),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: AppSearchField(
                        variant: AppSearchFieldVariant.bordered,
                        hint: 'branches.search_hint'.tr(),
                        showMicIcon: false,
                        readOnly: true,
                        onTap: () => showBranchSearchSheet(context),
                      ),
                    ),
                  ),
                ),
                // Filter chips — scroll with content, below the pinned search.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: _FilterRow(currentFilter: state.filter),
                  ),
                ),
                if (state.hasError && state.branches.isEmpty)
                  AppSliverFillRemaining(
                    child: _ErrorState(
                      failure: state.failure,
                      onRetry: () => context.read<BranchesBloc>().add(
                        const BranchesRefreshEvent(),
                      ),
                    ),
                  )
                else if (branches.isEmpty)
                  AppSliverFillRemaining(
                    child: _EmptyState(
                      searchQuery: state.searchQuery,
                      onClearSearch: () => context.read<BranchesBloc>().add(
                        const BranchesSearchChangedEvent(''),
                      ),
                    ),
                  )
                else ...[
                  SliverList.builder(
                    itemCount: branches.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      child: BranchListItem(branch: branches[index]),
                    ),
                  ),
                  // "Add Branches" button at the bottom of the list.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.lg,
                      ),
                      child: AppButton(
                        label: 'branches.add_button'.tr(),
                        icon: const Icon(Icons.add_circle_outline),
                        iconPosition: AppButtonIconPosition.center,
                        onPressed: () => context.push(BranchRoutes.add),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Company row and title — collapses away on scroll.
class _CollapsingHeader extends StatelessWidget {
  const _CollapsingHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBar(
          title: Text('branches.company_name'.tr()),
          centerTitle: false,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            //notification icon
            Padding(
              padding: EdgeInsetsGeometry.only(left: AppSpacing.md),
              child: AppNotificationIcon(
                hasUnread: true,
                onTap: () {},
              ),
            ),
          ],
        ),
        AppSection(title: 'branches.title'.tr()),
      ],
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
            onPressed: () => context.read<BranchesBloc>().add(
              const BranchesFilterChangedEvent(BranchFilter.all),
            ),
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
            onPressed: () => context.read<BranchesBloc>().add(
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
            onPressed: () => context.read<BranchesBloc>().add(
              const BranchesFilterChangedEvent(BranchFilter.active),
            ),
          ),
        ),
      ],
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
          query: searchQuery,
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
      ),
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

    final description = (f != null && f.message.isNotEmpty)
        ? f.message.tr()
        : 'branches.load_error_description'.tr();

    return Center(
      child: AppGenericEmptyState(
        title: 'branches.load_error_title'.tr(),
        description: description,
        actionLabel: 'branches.load_error_action'.tr(),
        onAction: onRetry,
      ),
    );
  }
}
