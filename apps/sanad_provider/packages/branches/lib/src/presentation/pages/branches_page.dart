import 'package:auth/auth.dart';
import 'package:authorization/authorization.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_filter.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/presentation/bloc/swipe_hint/swipe_hint_bloc.dart';
import 'package:branches/src/presentation/widgets/branch_empty_states.dart';
import 'package:branches/src/presentation/widgets/branch_list_item.dart';
import 'package:branches/src/presentation/widgets/branch_search_sheet.dart';
import 'package:branches/src/routes/branch_permissions.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';

/// Realistic mock used only to skeletonize the real row via
/// [AppSkeletonizer] — no bespoke skeleton widget.
final _skeletonBranch = BranchEntity(
  id: 'skeleton',
  branchName: BoneMock.words(2),
  branchAddress: BoneMock.address,
  city: BoneMock.city,
  branchPhone: BoneMock.phone,
  isAvailable: true,
  availabilityMode: BranchAvailabilityMode.coreHours,
);

/// Figma Branches screen (`73:2902`), collapsing header.
///
/// Company row and title collapse away on scroll; search bar stays pinned.
/// Filter chips and branch cards scroll below. "Add Branches" button sits
/// at the bottom of the scrollable content.
class ProviderBranchesPage extends StatefulWidget {
  const ProviderBranchesPage({required this.isOwner, super.key});

  /// Whether the signed-in account is a provider owner (individual or
  /// organization) — threaded down to [BranchListItem] to gate the
  /// Delete swipe, which is persona-controlled (no `provider:branch:
  /// delete` permission exists — RBAC backend gap G2).
  final bool isOwner;

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
    // The business name comes from the auth session's provider profile
    // (BusinessProviderProfileModel — shared shape for individual and
    // company providers), the same authoritative source
    // OrganizationSettingsPage resolves it from — never a localized string.
    final profile = sl<SessionManager>().profile;
    final businessName = profile is BusinessProviderProfileModel
        ? profile.businessName
        : null;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: _BranchesTab(
          isOwner: widget.isOwner,
          businessName: businessName,
        ),
      ),
    );
  }
}

class _BranchesTab extends StatefulWidget {
  const _BranchesTab({required this.isOwner, required this.businessName});

  final bool isOwner;

  /// `null` until the business has a name on file (e.g. fresh onboarding) —
  /// the header omits the company row rather than showing a placeholder.
  final String? businessName;

  @override
  State<_BranchesTab> createState() => _BranchesTabState();
}

class _BranchesTabState extends State<_BranchesTab> {
  static const double _titleSectionHeight = 60;
  static const double _headerSafetyMargin = 20;

  /// Only the first row, and only once — hint arms only after the persisted
  /// flag has been loaded, has never been seen, and hasn't yet fired this
  /// session (all tracked by [SwipeHintBloc]).
  bool _showSwipeHintFor(int index, SwipeHintState hint) =>
      index == 0 && hint.shouldArm;

  void _markHintShown() =>
      context.read<SwipeHintBloc>().add(const SwipeHintMarkedSeen());

  /// Pinned search row: bordered field height + vertical padding around it.
  /// Must match the [PreferredSize] child exactly to avoid RenderFlex overflow.
  double _bottomBarHeight() =>
      responsiveDimension(FieldTokens.fieldHeight) +
      (responsiveSpacing(10) * 2);

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
        final failure = state.actionFailure!;
        final title = failure.message.trim().isEmpty
            ? 'branches.actions.action_failed'.tr()
            : failure.localizedSafeMessage();
        showAppErrorSnackbar(context: context, title: title);
        context.read<BranchesBloc>().add(
          const BranchActionFailureClearedEvent(),
        );
      },
      child: BlocBuilder<BranchesBloc, BranchesState>(
        builder: (context, state) {
          if (state.isLoading) {
            // First-page load: skeletonize the *real* row widget with mock
            // data (no bespoke skeleton layout).
            return AppSkeletonList(
              itemBuilder: (_, _) => BranchListItem(branch: _skeletonBranch),
            );
          }

          final branches = state.filteredBranches;
          final colors = context.appColors;

          return AppRefreshIndicator(
            onRefresh: () async {
              context.read<BranchesBloc>().add(const BranchesRefreshEvent());
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Dispatch load-more when the user is within ~200px of the
                // bottom. The bloc's droppable() transformer + PaginationMixin
                // (checks !hasMore / already loadingMore) make this safe to
                // fire on every notification.
                if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200 &&
                    state.hasMore &&
                    !state.loadingMore) {
                  context.read<BranchesBloc>().add(
                    const BranchesLoadMoreEvent(),
                  );
                }
                return false;
              },
              child: AppSwipeActionsGroup(
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
                          child: _CollapsingHeader(
                            businessName: widget.businessName,
                          ),
                        ),
                      ),
                      bottom: PreferredSize(
                        preferredSize: Size.fromHeight(_bottomBarHeight()),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: responsiveSpacing(10),
                          ),
                          child: AppSearchField(
                            variant: AppSearchFieldVariant.bordered,
                            hint: 'common.search_hint'.tr(),
                            showMicIcon: false,
                            readOnly: true,
                            onTap: () => showBranchSearchSheet(
                              context,
                              isOwner: widget.isOwner,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
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
                      SliverList.separated(
                        itemCount: branches.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) => RepaintBoundary(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            child: BlocBuilder<SwipeHintBloc, SwipeHintState>(
                              builder: (context, hint) =>
                                  _showSwipeHintFor(index, hint)
                                  ? AppSwipeActionHint(
                                      enabled: true,
                                      onShown: _markHintShown,
                                      builder: (context, controller) =>
                                          BranchListItem(
                                            branch: branches[index],
                                            isOwner: widget.isOwner,
                                            hintController: controller,
                                          ),
                                    )
                                  : BranchListItem(
                                      branch: branches[index],
                                      isOwner: widget.isOwner,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          child: PermissionGate(
                            permission: BranchPermissions.create,
                            child: AppButton(
                              label: 'branches.add_button'.tr(),
                              icon: const Icon(Icons.add_circle_outline),
                              iconPosition: AppButtonIconPosition.center,
                              onPressed: () => _openAddBranch(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (state.loadingMore)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: const Center(child: AppLoadingIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Company row and title — collapses away on scroll.
class _CollapsingHeader extends StatelessWidget {
  const _CollapsingHeader({required this.businessName});

  /// The authenticated organization's business name, or `null` if it isn't
  /// on file yet — never a hardcoded/sample company name.
  final String? businessName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNavBar(
          title: businessName ?? '',
          showBackButton: true,
          onLeadingTap: () => context.pop(),
          trailingAction: AppNavBarTrailingAction.icon,
          trailing: AppNotificationIcon(hasUnread: true, onTap: () {}),
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
        _FilterChip(
          label: 'branches.filter_all'.tr(),
          selected: currentFilter == BranchFilter.all,
          onTap: () => context.read<BranchesBloc>().add(
            const BranchesFilterChangedEvent(BranchFilter.all),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        _FilterChip(
          label: 'branches.filter_maintenance'.tr(),
          selected: currentFilter == BranchFilter.maintenance,
          onTap: () => context.read<BranchesBloc>().add(
            const BranchesFilterChangedEvent(BranchFilter.maintenance),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        _FilterChip(
          label: 'branches.filter_active'.tr(),
          selected: currentFilter == BranchFilter.active,
          onTap: () => context.read<BranchesBloc>().add(
            const BranchesFilterChangedEvent(BranchFilter.active),
          ),
        ),
      ],
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
    return AppButton(
      label: label,
      size: AppButtonSize.small,
      variant: selected ? AppButtonVariant.secondary : AppButtonVariant.outline,
      onPressed: onTap,
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
      child: PermissionBuilder(
        requirement: const PermissionRequirement.single(
          BranchPermissions.create,
        ),
        builder: (context, allowed) => BranchesEmptyState(
          // A view-only worker sees "no branches yet" with no action —
          // this is the read-only-page distinction: the surface itself is
          // never hidden (branchView already got them here), only the
          // mutation is.
          onAddBranch: allowed ? () => _openAddBranch(context) : null,
        ),
      ),
    );
  }
}

/// Opens the add-branch flow and refreshes the list if a branch was added.
/// The add page pops `true` on success — see EH-S3-02 refresh convention.
Future<void> _openAddBranch(BuildContext context) async {
  final added = await context.push<bool>(BranchRoutes.add);
  if ((added ?? false) && context.mounted) {
    context.read<BranchesBloc>().add(const BranchesRefreshEvent());
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, this.failure});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final display = failureErrorDisplay(
      failure,
      genericTitleKey: 'branches.load_error_title',
      genericDescriptionKey: 'branches.load_error_description',
    );
    return AppErrorState(
      style: display.isConnectivity
          ? AppErrorStateStyle.network
          : AppErrorStateStyle.generic,
      title: display.title,
      description: display.description,
      retryLabel: display.isConnectivity
          ? failureRetryLabel()
          : 'branches.load_error_action'.tr(),
      onRetry: display.isRetryable ? onRetry : null,
    );
  }
}
