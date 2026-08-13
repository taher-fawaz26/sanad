import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/presentation/bloc/role_form/role_form_bloc.dart';
import 'package:provider_rbac/src/presentation/widgets/permission_group_card.dart';
import 'package:shared_ui/shared_ui.dart';

/// Realistic mock used only to skeletonize the real permission-group cards
/// via [AppSkeletonizer] while the catalog loads — no bespoke skeleton
/// layout.
final _skeletonPermissions = [
  for (var g = 0; g < 2; g++)
    for (var i = 0; i < 3; i++)
      PermissionEntity(
        id: 'skeleton-$g-$i',
        action: 'skeleton',
        displayName: BoneMock.words(2),
        resource: 'skeleton-resource-$g',
      ),
];

/// Create-role and edit-role form — Figma `Create New Role` (`5492:24051`).
///
/// Edit mode is signalled by a non-null [existingRole]; the first field
/// swaps to "Modification Title" (`5492:24880`) but everything else is
/// shared between the two modes.
class RoleFormPage extends StatefulWidget {
  const RoleFormPage({this.existingRole, super.key});

  final RoleEntity? existingRole;

  bool get isEdit => existingRole != null;

  @override
  State<RoleFormPage> createState() => _RoleFormPageState();
}

class _RoleFormPageState extends State<RoleFormPage> {
  final _formKey = GlobalKey<FormState>();
  // Create: the role name. Edit: the "Modification Title" (UI-only) — both
  // start empty, so the controller is never seeded from the existing role.
  final _nameController = TextEditingController();
  late final _descriptionController = TextEditingController(
    text: widget.existingRole?.description,
  );

  @override
  void initState() {
    super.initState();
    context.read<RoleFormBloc>().add(
      LoadPermissionCatalogEvent(initialRole: widget.existingRole),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Derives the backend `name` slug (`^[a-z0-9-]$`, ≤50 chars) from the
  /// human display name — matches the backend's stored slugs
  /// (e.g. "Senior Branch Manager" → "senior-branch-manager").
  String _slugify(String input) {
    final slug = input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('^-+|-+\$'), '');
    return slug.length > 50 ? slug.substring(0, 50) : slug;
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final input = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    final bloc = context.read<RoleFormBloc>();
    final existing = widget.existingRole;
    if (existing == null) {
      // Create: `displayName` is what the user typed; `name` is its slug.
      bloc.add(
        SubmitCreateRoleEvent(
          name: _slugify(input),
          displayName: input,
          description: description.isEmpty ? null : description,
        ),
      );
    } else {
      // Edit preserves the role identity (name/displayName). Only the
      // description and permission set are editable here; the "Modification
      // Title" field is a UI-only audit label with no `UpdateRoleDto` field.
      bloc.add(
        SubmitUpdateRoleEvent(
          roleId: existing.id,
          name: existing.name,
          displayName: existing.displayName,
          description: description.isEmpty ? null : description,
        ),
      );
    }
  }

  Map<String, List<PermissionEntity>> _groupByResource(
    List<PermissionEntity> permissions,
  ) {
    final grouped = <String, List<PermissionEntity>>{};
    for (final permission in permissions) {
      grouped.putIfAbsent(permission.resource, () => []).add(permission);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<RoleFormBloc, RoleFormState>(
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == RoleFormSubmitStatus.success) {
          context.pop(true);
        } else if (state.submitStatus == RoleFormSubmitStatus.failure) {
          showAppErrorSnackbar(
            context: context,
            title: 'provider_rbac.action_failed'.tr(),
            caption: state.failure?.localizedMessage() ?? '',
          );
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavBar(
                title: widget.isEdit
                    ? 'provider_rbac.edit_role_title'.tr()
                    : 'provider_rbac.add_role_title'.tr(),
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
                child: AppSegmentedControl<int>(
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
                  onChanged: (_) {},
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _nameController,
                          label: widget.isEdit
                              ? 'provider_rbac.modification_title_label'.tr()
                              : 'provider_rbac.name_label'.tr(),
                          hint: widget.isEdit
                              ? 'provider_rbac.modification_title_hint'.tr()
                              : 'provider_rbac.name_hint'.tr(),
                          isRequired: true,
                          validator: (value) => (value?.trim().isEmpty ?? true)
                              ? 'provider_rbac.validation_required'.tr()
                              : null,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Stack(
                          children: [
                            AppTextField(
                              controller: _descriptionController,
                              label: 'provider_rbac.description_label'.tr(),
                              hint: 'provider_rbac.description_hint'.tr(),
                              isRequired: true,
                              maxLines: 5,
                              validator: (value) =>
                                  (value?.trim().isEmpty ?? true)
                                  ? 'provider_rbac.validation_required'.tr()
                                  : null,
                            ),
                            Positioned(
                              right: AppSpacing.sm,
                              bottom: AppSpacing.sm,
                              child: AppEnhanceWithAiButton(
                                label: 'provider_rbac.enhance_with_ai'.tr(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.lg),
                        BlocBuilder<RoleFormBloc, RoleFormState>(
                          builder: (context, state) {
                            if (state.catalogStatus == RequestStatus.failure &&
                                state.permissions.isEmpty) {
                              return AppGenericEmptyState(
                                title: 'provider_rbac.load_failed'.tr(),
                                description:
                                    state.failure?.localizedMessage() ?? '',
                              );
                            }
                            if (state.isCatalogLoading) {
                              // Skeletonize the *real* permission-group cards
                              // with mock data instead of a bespoke skeleton.
                              final grouped = _groupByResource(
                                _skeletonPermissions,
                              );
                              final resources = grouped.keys.toList()..sort();
                              return AppSkeletonizer(
                                enabled: true,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (
                                      var i = 0;
                                      i < resources.length;
                                      i++
                                    ) ...[
                                      if (i > 0)
                                        SizedBox(height: AppSpacing.md),
                                      PermissionGroupCard(
                                        resource: resources[i],
                                        permissions: grouped[resources[i]]!,
                                        selectedIds: const {},
                                        onToggle: (_) {},
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }
                            final grouped = _groupByResource(
                              state.permissions,
                            );
                            final resources = grouped.keys.toList()..sort();
                            final bloc = context.read<RoleFormBloc>();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0; i < resources.length; i++) ...[
                                  if (i > 0) SizedBox(height: AppSpacing.md),
                                  PermissionGroupCard(
                                    resource: resources[i],
                                    permissions: grouped[resources[i]]!,
                                    selectedIds: state.selectedPermissionIds,
                                    onToggle: (id) =>
                                        bloc.add(TogglePermissionEvent(id)),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: BlocBuilder<RoleFormBloc, RoleFormState>(
                  builder: (context, state) => AppButton(
                    label: widget.isEdit
                        ? 'provider_rbac.save_changes_button'.tr()
                        : 'provider_rbac.create_new_role_button'.tr(),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    iconPosition: AppButtonIconPosition.center,
                    isLoading: state.isSubmitting,
                    onPressed: state.canSubmit ? _onSubmit : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
