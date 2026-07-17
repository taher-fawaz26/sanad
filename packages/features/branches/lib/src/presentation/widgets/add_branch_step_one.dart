import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:branches/src/presentation/widgets/branch_location_field.dart';
import 'package:branches/src/presentation/widgets/branch_manager_picker_field.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:branches/src/presentation/widgets/branch_type_select_field.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';

class AddBranchStepOne extends StatefulWidget {
  const AddBranchStepOne({
    required this.formKey,
    required this.onPickLocation,
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final VoidCallback onPickLocation;
  final int currentStep;
  final int totalSteps;

  @override
  State<AddBranchStepOne> createState() => _AddBranchStepOneState();
}

class _AddBranchStepOneState extends State<AddBranchStepOne> {
  final _branchNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _setupSeeded = false;

  @override
  void initState() {
    super.initState();
    final draft = context.read<AddBranchDraftCubit>().state;
    _branchNameController.text = draft.branchName;
    _cityController.text = draft.city;
    _phoneController.text = draft.phone;

    _branchNameController.addListener(_pushBasicInfoToDraft);
    _cityController.addListener(_pushBasicInfoToDraft);
    _phoneController.addListener(_pushBasicInfoToDraft);
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _pushBasicInfoToDraft() {
    context.read<AddBranchDraftCubit>().updateBasicInfo(
          branchName: _branchNameController.text,
          city: _cityController.text,
          phone: _phoneController.text,
        );
  }

  void _seedFromSetup(AddBranchState state) {
    if (_setupSeeded || state.setupStatus != RequestStatus.success) return;
    _setupSeeded = true;

    final draftCubit = context.read<AddBranchDraftCubit>();

    // Initialize custom schedule from company schedule if not already set.
    draftCubit.initializeCustomSchedule(
      BranchScheduleFormatter.copyAvailability(state.companySchedule),
    );

    // Auto-select first manager if none selected yet.
    if (draftCubit.state.selectedManagerId == null &&
        state.managers.isNotEmpty) {
      draftCubit.updateManager(state.managers.first.id);
    }
  }

  void _onScheduleModeChanged(BranchScheduleMode mode) {
    final draftCubit = context.read<AddBranchDraftCubit>();
    draftCubit.updateScheduleMode(mode);

    if (mode == BranchScheduleMode.custom &&
        draftCubit.state.customSchedule.isEmpty) {
      final companySchedule =
          context.read<AddBranchBloc>().state.companySchedule;
      if (companySchedule.isNotEmpty) {
        draftCubit.updateCustomSchedule(
          BranchScheduleFormatter.copyAvailability(companySchedule),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddBranchBloc, AddBranchState>(
      listenWhen: (prev, curr) => prev.setupStatus != curr.setupStatus,
      listener: (_, state) => _seedFromSetup(state),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppLargeNavBar(
                title: 'branches.add_branch.title'.tr(),
                caption: 'branches.add_branch.subtitle'.tr(),
                useLargeTitleStyle: false,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: AppWizardStepIndicator(
                  currentStep: widget.currentStep,
                  totalSteps: widget.totalSteps,
                ),
              ),
              _MainInfoSection(
                branchNameController: _branchNameController,
                cityController: _cityController,
                onPickLocation: widget.onPickLocation,
              ),
              const AppDivider(thickness: AppDividerThickness.thick),
              _ContactSection(phoneController: _phoneController),
              const AppDivider(thickness: AppDividerThickness.thick),
              _WorkingHoursSection(
                onScheduleModeChanged: _onScheduleModeChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainInfoSection extends StatelessWidget {
  const _MainInfoSection({
    required this.branchNameController,
    required this.cityController,
    required this.onPickLocation,
  });

  final TextEditingController branchNameController;
  final TextEditingController cityController;
  final VoidCallback onPickLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.add_branch.section_main_info'.tr(),
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
                controller: branchNameController,
                label: 'branches.add_branch.branch_name'.tr(),
                hint: 'branches.add_branch.branch_name_hint'.tr(),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return ValidationMessageKeys.formRequired;
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.md),
              BlocSelector<AddBranchDraftCubit, AddBranchDraft, BranchType>(
                selector: (state) => state.branchType,
                builder: (context, selectedType) {
                  return BranchTypeSelectField(
                    selectedType: selectedType,
                    onTypeSelected: (type) {
                      context.read<AddBranchDraftCubit>().updateBranchType(type);
                    },
                  );
                },
              ),
              SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: cityController,
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
              BlocSelector<AddBranchDraftCubit, AddBranchDraft, String?>(
                selector: (state) => state.branchAddress,
                builder: (context, address) {
                  return BranchLocationField(
                    label: 'branches.add_branch.location'.tr(),
                    value: address,
                    hint: 'branches.add_branch.location_hint'.tr(),
                    actionLabel: 'branches.add_branch.location_set'.tr(),
                    onActionTap: onPickLocation,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.phoneController});

  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.add_branch.section_contact'.tr(),
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
                label: 'branches.add_branch.branch_phone'.tr(),
                controller: phoneController,
                hint: 'branches.add_branch.branch_phone_hint'.tr(),
              ),
              SizedBox(height: AppSpacing.md),
              BlocSelector<AddBranchBloc, AddBranchState,
                  List<BranchManagerEntity>>(
                selector: (state) => state.managers,
                builder: (context, managers) {
                  return BlocSelector<AddBranchDraftCubit, AddBranchDraft,
                      String?>(
                    selector: (state) => state.selectedManagerId,
                    builder: (context, selectedManagerId) {
                      final selectedManager = managers
                          .where((m) => m.id == selectedManagerId)
                          .firstOrNull;
                      return BranchManagerPickerField(
                        managers: managers,
                        selectedManager: selectedManager,
                        onManagerSelected: (manager) {
                          context
                              .read<AddBranchDraftCubit>()
                              .updateManager(manager.id);
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkingHoursSection extends StatelessWidget {
  const _WorkingHoursSection({required this.onScheduleModeChanged});

  final ValueChanged<BranchScheduleMode> onScheduleModeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.add_branch.section_working_hours'.tr(),
          size: AppSectionSize.compact,
          tone: AppSectionTone.primary,
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: BlocSelector<AddBranchBloc, AddBranchState, bool>(
            selector: (state) => state.isLoadingSetup,
            builder: (context, isLoadingSetup) {
              if (isLoadingSetup) {
                return const Center(child: CircularProgressIndicator());
              }
              return BlocBuilder<AddBranchBloc, AddBranchState>(
                buildWhen: (prev, curr) =>
                    prev.companySchedule != curr.companySchedule,
                builder: (context, blocState) {
                  return BlocSelector<AddBranchDraftCubit, AddBranchDraft,
                      ({
                        BranchScheduleMode mode,
                        List<BranchAvailabilityEntity> customSchedule,
                      })>(
                    selector: (state) => (
                      mode: state.scheduleMode,
                      customSchedule: state.customSchedule,
                    ),
                    builder: (context, draft) {
                      return BranchScheduleSection(
                        mode: draft.mode,
                        companySchedule: blocState.companySchedule,
                        customSchedule: draft.customSchedule,
                        onModeChanged: onScheduleModeChanged,
                        onCustomScheduleChanged: (schedule) {
                          context
                              .read<AddBranchDraftCubit>()
                              .updateCustomSchedule(schedule);
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
