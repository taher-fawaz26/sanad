import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';
import 'package:provider_rbac/src/presentation/bloc/role_action/role_action_bloc.dart';
import 'package:provider_rbac/src/presentation/bloc/roles_list/roles_list_bloc.dart';
import 'package:provider_rbac/src/presentation/widgets/role_actions_bottom_sheet.dart';
import 'package:provider_rbac/src/presentation/widgets/role_list_item.dart';
import 'package:provider_rbac/src/routes/provider_rbac_routes.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// The "Roles" pane — Figma `roles-permissions-mobile` (`5494:22572`), minus
/// the nav bar and segmented control (owned by the host screen).
///
/// Self-contained: it provides its own [RolesListBloc] / [RoleActionBloc], so
/// it can be dropped into the Workers screen's segmented control (as the third
/// tab, alongside Team / Invitations) or wrapped by the standalone
/// `RolesListPage` route — without the host having to supply the BLoCs.
/// Realistic mock used only to skeletonize the real row via
/// [AppSkeletonizer] — no bespoke skeleton widget.
final _skeletonRole = RoleEntity(
  id: 'skeleton',
  name: 'skeleton',
  displayName: BoneMock.words(2),
  userType: RolePersonaType.worker,
  isSystem: false,
  permissions: const [],
);

class RolesContent extends StatelessWidget {
  const RolesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<RolesListBloc>()),
        BlocProvider(create: (_) => sl<RoleActionBloc>()),
      ],
      child: const _RolesView(),
    );
  }
}

class _RolesView extends StatefulWidget {
  const _RolesView();

  @override
  State<_RolesView> createState() => _RolesViewState();
}

class _RolesViewState extends State<_RolesView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RolesListBloc>().add(const LoadRolesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onAdd() async {
    final created = await context.push<bool>(ProviderRbacRoutes.add);
    if ((created ?? false) && mounted) {
      context.read<RolesListBloc>().add(const RefreshRolesEvent());
    }
  }

  void _onViewDetails(RoleEntity role) {
    context.push(ProviderRbacRoutes.detailsFor(role.id), extra: role);
  }

  Future<void> _onEdit(RoleEntity role) async {
    final updated = await context.push<bool>(
      ProviderRbacRoutes.editFor(role.id),
      extra: role,
    );
    if ((updated ?? false) && mounted) {
      context.read<RolesListBloc>().add(const RefreshRolesEvent());
    }
  }

  Future<void> _onDelete(RoleEntity role) async {
    final confirmed = await SheetNavigator.push<bool>(
      context,
      AppConfirmationContent(
        title: 'provider_rbac.delete_role_title'.tr(),
        description: 'provider_rbac.delete_role_description'.tr(
          namedArgs: {'name': role.displayName},
        ),
        actionLabel: 'provider_rbac.delete_confirm'.tr(),
        cancelLabel: 'provider_rbac.cancel'.tr(),
        destructive: true,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
      settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
    );
    if (confirmed != true || !mounted) return;
    context.read<RoleActionBloc>().add(DeleteRoleRequestedEvent(role.id));
  }

  void _onMoreTap(RoleEntity role) {
    showRoleActionsBottomSheet(
      context: context,
      role: role,
      onViewDetails: () => _onViewDetails(role),
      // System roles are read-only per the backend (edit/delete → 403).
      onEdit: role.isSystem ? null : () => _onEdit(role),
      onDelete: role.isSystem ? null : () => _onDelete(role),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoleActionBloc, RoleActionState>(
      listener: (context, state) {
        switch (state.status) {
          case RoleActionStatus.success:
            final roleId = state.roleId;
            if (roleId != null) {
              context.read<RolesListBloc>().add(
                RoleRemovedFromListEvent(roleId),
              );
            }
            showAppSnackbar(
              context: context,
              title: 'provider_rbac.delete_role_success'.tr(),
            );
          case RoleActionStatus.failure:
            showAppErrorSnackbar(
              context: context,
              title: 'provider_rbac.action_failed'.tr(),
              caption: state.failure?.localizedMessage() ?? '',
            );
          case RoleActionStatus.idle:
          case RoleActionStatus.inProgress:
            break;
        }
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: AppSearchField(
                  controller: _searchController,
                  hint: 'provider_rbac.search_hint'.tr(),
                  showMicIcon: false,
                  variant: AppSearchFieldVariant.bordered,
                  onChanged: (value) => context.read<RolesListBloc>().add(
                    SearchRolesChangedEvent(value),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<RolesListBloc, RolesListState>(
                  builder: (context, state) => _buildBody(context, state),
                ),
              ),
            ],
          ),
          PositionedDirectional(
            end: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: AppFloatingActionButton(
              onPressed: _onAdd,
              semanticLabel: 'provider_rbac.add_role_title'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  /// First-page loading / error / empty are handled here (plain box layout),
  /// not through [SanadPagedList]'s indicators; the paged list is used only
  /// once items exist, so it renders only rows + inline load-more indicators.
  Widget _buildBody(BuildContext context, RolesListState state) {
    if (state.isLoading && state.roles.isEmpty) {
      // First-page load: skeletonize the *real* row widget with mock data
      // (no bespoke skeleton layout).
      return AppSkeletonList(
        itemBuilder: (_, _) => RoleCard(role: _skeletonRole),
      );
    }
    if (state.hasError && state.roles.isEmpty) {
      return _fillRefresh(
        child: AppGenericEmptyState(
          title: 'provider_rbac.load_failed'.tr(),
          description: state.failure?.localizedMessage() ?? '',
          actionLabel: failureRetryLabel(),
          onAction: () =>
              context.read<RolesListBloc>().add(const LoadRolesEvent()),
        ),
      );
    }
    if (state.isEmpty) {
      return _fillRefresh(
        child: AppGenericEmptyState(
          title: 'provider_rbac.empty_title'.tr(),
          description: 'provider_rbac.empty_description'.tr(),
        ),
      );
    }
    return AppRefreshIndicator(
      onRefresh: () async {
        context.read<RolesListBloc>().add(const RefreshRolesEvent());
      },
      child: SanadPagedList<RoleEntity>(
        state: toPagingState(state.pagination),
        fetchNextPage: () =>
            context.read<RolesListBloc>().add(const LoadMoreRolesEvent()),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          // Leave room for the floating "add" button.
          AppSpacing.xxxl * 2,
        ),
        separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md),
        itemBuilder: (context, role, index) => RepaintBoundary(
          child: RoleCard(role: role, onMoreTap: () => _onMoreTap(role)),
        ),
        // Unreachable while items exist (handled above); kept safe & cheap.
        firstPageErrorIndicatorBuilder: (_) => const SizedBox.shrink(),
        noItemsFoundIndicatorBuilder: (_) => const SizedBox.shrink(),
        newPageErrorIndicatorBuilder: (_) => _NextPageErrorRetry(
          onRetry: () =>
              context.read<RolesListBloc>().add(const LoadMoreRolesEvent()),
        ),
      ),
    );
  }

  /// A full-height, pull-to-refresh wrapper for the empty / error states.
  Widget _fillRefresh({required Widget child}) {
    return AppRefreshIndicator(
      onRefresh: () async {
        context.read<RolesListBloc>().add(const RefreshRolesEvent());
      },
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Compact "load more failed" footer — keeps already-loaded rows visible.
class _NextPageErrorRetry extends StatelessWidget {
  const _NextPageErrorRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: GestureDetector(
          onTap: onRetry,
          behavior: HitTestBehavior.opaque,
          child: Text(
            failureRetryLabel(),
            style: context.appTypography.regularNormal.copyWith(
              color: context.appColors.link,
            ),
          ),
        ),
      ),
    );
  }
}
