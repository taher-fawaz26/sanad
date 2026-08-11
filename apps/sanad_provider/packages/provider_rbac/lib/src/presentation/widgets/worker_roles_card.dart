import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:provider_rbac/src/presentation/bloc/worker_roles/worker_roles_bloc.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

const _cardRadius = 16.0;

/// "Assigned roles" card for the worker-details screen — implements the
/// `workers`-defined `WorkerRoleAssigner.buildRolesCard` port. Fetches and
/// owns its own [WorkerRolesBloc] instance so `workers` never has to know
/// this package (or `provider_rbac`'s roles data) exists.
class WorkerRolesCard extends StatelessWidget {
  const WorkerRolesCard({required this.workerId, super.key});

  final String workerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WorkerRolesBloc>()..add(LoadWorkerRolesEvent(workerId)),
      child: _WorkerRolesCardBody(workerId: workerId),
    );
  }
}

class _WorkerRolesCardBody extends StatelessWidget {
  const _WorkerRolesCardBody({required this.workerId});

  final String workerId;

  Future<void> _openManageSheet(BuildContext context) async {
    final bloc = context.read<WorkerRolesBloc>()
      ..add(const LoadAssignableRolesEvent());

    await SheetNavigator.push<void>(
      context,
      BlocProvider.value(
        value: bloc,
        child: _ManageRolesSheetBody(workerId: workerId),
      ),
      settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final dark = colors.palettes.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: dark.shade50,
        borderRadius: BorderRadius.circular(responsiveDimension(_cardRadius)),
        border: Border.all(color: dark.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'provider_rbac.worker_roles_title'.tr(),
                  style: typography.regularNormal.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openManageSheet(context),
                child: Text(
                  'provider_rbac.manage_roles'.tr(),
                  style: typography.smallNormal.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          BlocBuilder<WorkerRolesBloc, WorkerRolesState>(
            builder: (context, state) {
              if (state.isLoading && state.roles.isEmpty) {
                return const Center(child: AppLoadingIndicator());
              }
              if (state.roles.isEmpty) {
                return Text(
                  'provider_rbac.no_assigned_roles'.tr(),
                  style: typography.smallNormal.copyWith(
                    color: colors.textMuted,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < state.roles.length; i++) ...[
                    if (i > 0) SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            state.roles[i].displayName,
                            style: typography.smallNormal.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ManageRolesSheetBody extends StatefulWidget {
  const _ManageRolesSheetBody({required this.workerId});

  final String workerId;

  @override
  State<_ManageRolesSheetBody> createState() => _ManageRolesSheetBodyState();
}

class _ManageRolesSheetBodyState extends State<_ManageRolesSheetBody> {
  late Set<String> _selectedRoleIds;
  bool _initialized = false;

  void _initSelection(WorkerRolesState state) {
    if (_initialized) return;
    _initialized = true;
    _selectedRoleIds = state.roles.map((r) => r.id).toSet();
  }

  void _onSave(BuildContext context) {
    context.read<WorkerRolesBloc>().add(
      AssignRolesRequestedEvent(
        workerId: widget.workerId,
        roleIds: _selectedRoleIds.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return BlocConsumer<WorkerRolesBloc, WorkerRolesState>(
      listenWhen: (previous, current) =>
          previous.mutationStatus != current.mutationStatus,
      listener: (context, state) {
        if (state.mutationStatus == RequestStatus.success) {
          Navigator.of(context).pop();
          showAppSnackbar(
            context: context,
            title: 'provider_rbac.assign_roles_success'.tr(),
          );
        } else if (state.mutationStatus == RequestStatus.failure) {
          showAppErrorSnackbar(
            context: context,
            title: 'provider_rbac.action_failed'.tr(),
            caption: state.failure?.localizedMessage() ?? '',
          );
        }
      },
      builder: (context, state) {
        _initSelection(state);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'provider_rbac.manage_roles'.tr(),
              style: typography.title2.copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: AppSpacing.md),
            if (state.catalogStatus == RequestStatus.loading &&
                state.catalog.isEmpty)
              const Center(child: AppLoadingIndicator())
            else if (state.catalogStatus == RequestStatus.failure &&
                state.catalog.isEmpty)
              AppGenericEmptyState(
                title: 'provider_rbac.load_failed'.tr(),
                description: state.failure?.localizedMessage() ?? '',
              )
            else
              for (final role in state.catalog)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      if (!_selectedRoleIds.remove(role.id)) {
                        _selectedRoleIds.add(role.id);
                      }
                    }),
                    child: Row(
                      children: [
                        AppCheckbox(
                          value: _selectedRoleIds.contains(role.id),
                          onChanged: (_) => setState(() {
                            if (!_selectedRoleIds.remove(role.id)) {
                              _selectedRoleIds.add(role.id);
                            }
                          }),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            role.displayName,
                            style: typography.regularNormal.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'provider_rbac.save_button'.tr(),
              isLoading: state.isMutating,
              onPressed: state.isMutating ? null : () => _onSave(context),
            ),
          ],
        );
      },
    );
  }
}
