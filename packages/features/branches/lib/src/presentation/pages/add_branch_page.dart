import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/widgets/branch_location_field.dart';
import 'package:branches/src/presentation/widgets/branch_person_select_field.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';

enum _ScheduleMode { company, custom }

/// Figma Add branch — Step 1 (`194:4056`).
class AddBranchPage extends StatefulWidget {
  const AddBranchPage({super.key});

  @override
  State<AddBranchPage> createState() => _AddBranchPageState();
}

class _AddBranchPageState extends State<AddBranchPage> {
  final _formKey = GlobalKey<FormState>();
  final _branchNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _branchAddress;
  _ScheduleMode _scheduleMode = _ScheduleMode.company;

  @override
  void dispose() {
    _branchNameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_branchAddress == null) {
      showAppSnackbar(
        context: context,
        title: 'branches.add_branch.location_required'.tr(),
      );
      return;
    }

    context.read<AddBranchBloc>().add(
          AddBranchSubmitEvent(
            params: CreateBranchParams(
              branchName: _branchNameController.text.trim(),
              branchAddress: _branchAddress!,
              city: _cityController.text.trim(),
              branchPhone: _phoneController.text.trim(),
              availabilityMode: _scheduleMode == _ScheduleMode.company
                  ? 'CORE_HOURS'
                  : 'CUSTOM',
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddBranchBloc, AddBranchState>(
      listener: (context, state) {
        if (state.isSuccess) {
          showAppSnackbar(
            context: context,
            title: 'branches.add_branch.success'.tr(),
            color: AppSnackbarColor.primary,
          );
          context.pop();
        } else if (state.hasError && state.failure != null) {
          showAppSnackbar(
            context: context,
            title: state.failure!.message,
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavBar(
                title: '',
                leading: AppCloseIcon(onTap: () => context.pop()),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppLargeNavBar(
                          title: 'branches.add_branch.title'.tr(),
                          caption: 'branches.add_branch.subtitle'.tr(),
                          useLargeTitleStyle: false,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          child: const AppWizardStepIndicator(
                            currentStep: 1,
                            totalSteps: 4,
                          ),
                        ),
                        AppSection(
                          title:
                              'branches.add_branch.section_main_info'.tr(),
                          size: AppSectionSize.compact,
                          tone: AppSectionTone.primary,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _branchNameController,
                                label:
                                    'branches.add_branch.branch_name'.tr(),
                                hint: 'branches.add_branch.branch_name_hint'
                                    .tr(),
                                validator: (value) {
                                  if (value?.trim().isEmpty ?? true) {
                                    return ValidationMessageKeys.formRequired;
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: AppSpacing.md),
                              AppTextField(
                                controller: _cityController,
                                label: 'branches.add_branch.city'.tr(),
                                hint: 'branches.add_branch.city_hint'.tr(),
                                validator: (value) {
                                  if (value?.trim().isEmpty ?? true) {
                                    return ValidationMessageKeys.formRequired;
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: AppSpacing.md),
                              BranchLocationField(
                                label: 'branches.add_branch.location'.tr(),
                                value: _branchAddress,
                                hint: 'branches.add_branch.location_hint'.tr(),
                                actionLabel:
                                    'branches.add_branch.location_set'.tr(),
                                onActionTap: () {
                                  // TODO(branches): integrate map picker
                                  setState(
                                    () => _branchAddress =
                                        _cityController.text.trim().isNotEmpty
                                            ? _cityController.text.trim()
                                            : 'Address',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const AppDivider(
                          thickness: AppDividerThickness.thick,
                        ),
                        AppSection(
                          title:
                              'branches.add_branch.section_contact'.tr(),
                          size: AppSectionSize.compact,
                          tone: AppSectionTone.primary,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          child: Column(
                            children: [
                              AppPhoneField(
                                label:
                                    'branches.add_branch.branch_phone'.tr(),
                                controller: _phoneController,
                                hint: 'branches.add_branch.branch_phone_hint'
                                    .tr(),
                              ),
                              SizedBox(height: AppSpacing.md),
                              BranchPersonSelectField(
                                label:
                                    'branches.add_branch.branch_manager'.tr(),
                                hint:
                                    'branches.add_branch.branch_manager_hint'
                                        .tr(),
                                enabled: false,
                              ),
                            ],
                          ),
                        ),
                        const AppDivider(
                          thickness: AppDividerThickness.thick,
                        ),
                        AppSection(
                          title: 'branches.add_branch.section_working_hours'
                              .tr(),
                          size: AppSectionSize.compact,
                          tone: AppSectionTone.primary,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          child: AppRadioGroup<_ScheduleMode>(
                            value: _scheduleMode,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _scheduleMode = value);
                              }
                            },
                            options: [
                              AppRadioOption(
                                value: _ScheduleMode.company,
                                label:
                                    'branches.add_branch.use_company_schedule'
                                        .tr(),
                              ),
                              AppRadioOption(
                                value: _ScheduleMode.custom,
                                label:
                                    'branches.add_branch.set_custom_schedule'
                                        .tr(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: BlocBuilder<AddBranchBloc, AddBranchState>(
                  builder: (context, state) => AppButton(
                    label: 'branches.add_branch.next_button'.tr(),
                    isLoading: state.isLoading,
                    onPressed: state.isLoading ? null : _submit,
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
