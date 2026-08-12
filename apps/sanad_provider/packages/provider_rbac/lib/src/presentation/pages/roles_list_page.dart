import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/presentation/bloc/role_action/role_action_bloc.dart';
import 'package:provider_rbac/src/presentation/bloc/roles_list/roles_list_bloc.dart';
import 'package:provider_rbac/src/presentation/widgets/role_actions_bottom_sheet.dart';
import 'package:provider_rbac/src/presentation/widgets/role_list_item.dart';
import 'package:provider_rbac/src/routes/provider_rbac_routes.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// "Roles" — Figma `roles-permissions-mobile` (`5494:22572`).
///
/// Lists system role templates (read-only) and the caller's custom roles
/// from `GET /provider/roles` (paginated), with create / edit / delete for
/// custom roles. System roles expose only "View details".
class RolesListPage extends StatefulWidget {
  const RolesListPage({super.key});

  @override
  State<RolesListPage> createState() => _RolesListPageState();
}

class _RolesListPageState extends State<RolesListPage> {
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
    final colors = context.appColors;

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
            final failure = state.failure;
            showAppErrorSnackbar(
              context: context,
              title: 'provider_rbac.action_failed'.tr(),
              caption: failure?.localizedMessage() ?? '',
            );
          case RoleActionStatus.idle:
          case RoleActionStatus.inProgress:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        floatingActionButton: AppFloatingActionButton(
          onPressed: _onAdd,
          semanticLabel: 'provider_rbac.add_role_title'.tr(),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavBar(
                title: 'provider_rbac.title'.tr(),
                showBackButton: true,
                onLeadingTap: () => context.pop(),
                trailing: AppNotificationIcon(onTap: () {}),
                trailingAction: AppNavBarTrailingAction.icon,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSegmentedControl<int>(
                      items: [
                        AppSegmentedControlItem(
                          value: 0,
                          label: 'provider_rbac.tab_team'.tr(),
                        ),
                        AppSegmentedControlItem(
                          value: 1,
                          label: 'provider_rbac.tab_invitations'.tr(),
                        ),
                        AppSegmentedControlItem(
                          value: 2,
                          label: 'provider_rbac.tab_roles'.tr(),
                        ),
                      ],
                      selectedValue: 2,
                      onChanged: (value) {
                        // Team / Invitations live on the Workers screen; this
                        // standalone Roles screen returns there.
                        if (value != 2) context.pop();
                      },
                    ),
                    SizedBox(height: AppSpacing.sm),
                    AppSearchField(
                      controller: _searchController,
                      hint: 'provider_rbac.search_hint'.tr(),
                      showMicIcon: false,
                      variant: AppSearchFieldVariant.bordered,
                      onChanged: (value) => context.read<RolesListBloc>().add(
                        SearchRolesChangedEvent(value),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<RolesListBloc, RolesListState>(
                  builder: (context, state) {
                    return AppRefreshIndicator(
                      onRefresh: () async {
                        context.read<RolesListBloc>().add(
                          const RefreshRolesEvent(),
                        );
                      },
                      child: SanadPagedList<RoleEntity>(
                        state: toPagingState(state.pagination),
                        fetchNextPage: () => context.read<RolesListBloc>().add(
                          const LoadMoreRolesEvent(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xxxl,
                        ),
                        separatorBuilder: (_, _) =>
                            SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, role, index) => RepaintBoundary(
                          child: RoleCard(
                            role: role,
                            onMoreTap: () => _onMoreTap(role),
                          ),
                        ),
                        firstPageErrorIndicatorBuilder: (_) => Center(
                          child: AppGenericEmptyState(
                            title: 'provider_rbac.load_failed'.tr(),
                            description:
                                state.failure?.localizedMessage() ?? '',
                            actionLabel: failureRetryLabel(),
                            onAction: () => context.read<RolesListBloc>().add(
                              const LoadRolesEvent(),
                            ),
                          ),
                        ),
                        newPageErrorIndicatorBuilder: (_) =>
                            _NextPageErrorRetry(
                              onRetry: () => context.read<RolesListBloc>().add(
                                const LoadMoreRolesEvent(),
                              ),
                            ),
                        noItemsFoundIndicatorBuilder: (_) => Center(
                          child: AppGenericEmptyState(
                            title: 'provider_rbac.empty_title'.tr(),
                            description: 'provider_rbac.empty_description'.tr(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
