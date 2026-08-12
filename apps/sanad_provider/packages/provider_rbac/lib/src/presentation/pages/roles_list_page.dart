import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/presentation/bloc/role_action/role_action_bloc.dart';
import 'package:provider_rbac/src/presentation/bloc/roles_list/roles_list_bloc.dart';
import 'package:provider_rbac/src/presentation/widgets/role_list_item.dart';
import 'package:provider_rbac/src/routes/provider_rbac_routes.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// "Roles & Permissions" — lists system role templates (read-only) and the
/// caller's custom roles, with create / edit / delete for custom roles.
class RolesListPage extends StatefulWidget {
  const RolesListPage({super.key});

  @override
  State<RolesListPage> createState() => _RolesListPageState();
}

class _RolesListPageState extends State<RolesListPage> {
  @override
  void initState() {
    super.initState();
    context.read<RolesListBloc>().add(const LoadRolesEvent());
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
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavBar(
                title: 'provider_rbac.title'.tr(),
                showBackButton: true,
                onLeadingTap: () => context.pop(),
                trailing: GestureDetector(
                  onTap: () async {
                    final created = await context.push<bool>(
                      ProviderRbacRoutes.add,
                    );
                    if ((created ?? false) && mounted) {
                      context.read<RolesListBloc>().add(
                        const RefreshRolesEvent(),
                      );
                    }
                  },
                  child: Icon(Icons.add, color: colors.primary),
                ),
              ),
              Expanded(
                child: BlocBuilder<RolesListBloc, RolesListState>(
                  builder: (context, state) {
                    if (state.isLoading && state.roles.isEmpty) {
                      return const Center(child: AppLoadingIndicator());
                    }
                    if (state.hasError && state.roles.isEmpty) {
                      return Center(
                        child: AppGenericEmptyState(
                          title: 'provider_rbac.load_failed'.tr(),
                          description: state.failure?.localizedMessage() ?? '',
                        ),
                      );
                    }
                    if (state.roles.isEmpty) {
                      return Center(
                        child: AppGenericEmptyState(
                          title: 'provider_rbac.empty_title'.tr(),
                          description: 'provider_rbac.empty_description'.tr(),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<RolesListBloc>().add(
                          const RefreshRolesEvent(),
                        );
                      },
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: state.roles.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: colors.gray200),
                        itemBuilder: (context, index) {
                          final role = state.roles[index];
                          return Dismissible(
                            key: ValueKey(role.id),
                            direction: role.isSystem
                                ? DismissDirection.none
                                : DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              await _onDelete(role);
                              return false;
                            },
                            background: const SizedBox.shrink(),
                            secondaryBackground: Container(
                              color: colors.error,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Icon(Icons.delete, color: colors.white),
                            ),
                            child: RoleListItem(
                              role: role,
                              onTap: () async {
                                final updated = await context.push<bool>(
                                  ProviderRbacRoutes.editFor(role.id),
                                  extra: role,
                                );
                                if ((updated ?? false) && mounted) {
                                  context.read<RolesListBloc>().add(
                                    const RefreshRolesEvent(),
                                  );
                                }
                              },
                            ),
                          );
                        },
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
