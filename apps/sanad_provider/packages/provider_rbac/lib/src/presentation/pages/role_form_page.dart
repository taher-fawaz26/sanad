import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/presentation/bloc/role_form/role_form_bloc.dart';
import 'package:provider_rbac/src/presentation/widgets/permission_multi_select_list.dart';
import 'package:shared_ui/shared_ui.dart';

/// Create-role and edit-role form. Edit mode is signalled by a non-null
/// [existingRole]; the API's `UpdateRoleDto` has every field optional, but
/// this form always resubmits the full current permission selection.
class RoleFormPage extends StatefulWidget {
  const RoleFormPage({this.existingRole, super.key});

  final RoleEntity? existingRole;

  bool get isEdit => existingRole != null;

  @override
  State<RoleFormPage> createState() => _RoleFormPageState();
}

class _RoleFormPageState extends State<RoleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.existingRole?.name,
  );
  late final _displayNameController = TextEditingController(
    text: widget.existingRole?.displayName,
  );
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
    _displayNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final description = _descriptionController.text.trim();

    final bloc = context.read<RoleFormBloc>();
    final existing = widget.existingRole;
    if (existing == null) {
      bloc.add(
        SubmitCreateRoleEvent(
          name: name,
          displayName: displayName,
          description: description.isEmpty ? null : description,
        ),
      );
    } else {
      bloc.add(
        SubmitUpdateRoleEvent(
          roleId: existing.id,
          name: name,
          displayName: displayName,
          description: description.isEmpty ? null : description,
        ),
      );
    }
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
                          label: 'provider_rbac.name_label'.tr(),
                          hint: 'provider_rbac.name_hint'.tr(),
                          isRequired: true,
                          validator: (value) => (value?.trim().isEmpty ?? true)
                              ? 'provider_rbac.validation_required'.tr()
                              : null,
                        ),
                        SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _displayNameController,
                          label: 'provider_rbac.display_name_label'.tr(),
                          hint: 'provider_rbac.display_name_hint'.tr(),
                          isRequired: true,
                          validator: (value) => (value?.trim().isEmpty ?? true)
                              ? 'provider_rbac.validation_required'.tr()
                              : null,
                        ),
                        SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _descriptionController,
                          label: 'provider_rbac.description_label'.tr(),
                          hint: 'provider_rbac.description_hint'.tr(),
                        ),
                        SizedBox(height: AppSpacing.xl),
                        Text(
                          'provider_rbac.permissions_label'.tr(),
                          style: context.appTypography.regularNormal.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        BlocBuilder<RoleFormBloc, RoleFormState>(
                          builder: (context, state) {
                            if (state.isCatalogLoading) {
                              return const Center(
                                child: AppLoadingIndicator(),
                              );
                            }
                            if (state.catalogStatus == RequestStatus.failure &&
                                state.permissions.isEmpty) {
                              return AppGenericEmptyState(
                                title: 'provider_rbac.load_failed'.tr(),
                                description:
                                    state.failure?.localizedMessage() ?? '',
                              );
                            }
                            return PermissionMultiSelectList(
                              permissions: state.permissions,
                              selectedIds: state.selectedPermissionIds,
                              onToggle: (id) => context
                                  .read<RoleFormBloc>()
                                  .add(TogglePermissionEvent(id)),
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
                        ? 'provider_rbac.save_button'.tr()
                        : 'provider_rbac.create_button'.tr(),
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
