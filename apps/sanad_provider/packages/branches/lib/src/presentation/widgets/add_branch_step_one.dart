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
import 'package:maps/maps.dart';

class AddBranchStepOne extends StatefulWidget {
  const AddBranchStepOne({
    required this.formKey,
    required this.onPickLocation,
    required this.currentStep,
    required this.totalSteps,
    this.furthestCompletedStep,
    this.onStepTapped,
    this.showValidationErrors = false,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final VoidCallback onPickLocation;
  final int currentStep;
  final int totalSteps;
  final int? furthestCompletedStep;
  final ValueChanged<int>? onStepTapped;

  /// When true, incomplete fields show the Figma inline error state
  /// (`1513:7801` error frame). Set after a failed Next attempt.
  final bool showValidationErrors;

  @override
  State<AddBranchStepOne> createState() => _AddBranchStepOneState();
}

class _AddBranchStepOneState extends State<AddBranchStepOne> {
  final _branchNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _setupSeeded = false;

  @override
  void initState() {
    super.initState();
    final draft = context.read<AddBranchDraftCubit>().state;
    _branchNameController.text = draft.branchName;
    _phoneController.text = draft.phone;

    _branchNameController.addListener(_pushBasicInfoToDraft);
    _phoneController.addListener(_pushBasicInfoToDraft);
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _pushBasicInfoToDraft() {
    context.read<AddBranchDraftCubit>().updateBasicInfo(
      branchName: _branchNameController.text,
      phone: _phoneController.text,
    );
  }

  void _seedFromSetup(AddBranchState state) {
    if (_setupSeeded || state.setupStatus != RequestStatus.success) return;
    _setupSeeded = true;

    context.read<AddBranchDraftCubit>().initializeCustomSchedule(
      BranchScheduleFormatter.copyAvailability(state.companySchedule),
    );
  }

  void _onScheduleModeChanged(BranchScheduleMode mode) {
    final draftCubit = context.read<AddBranchDraftCubit>();
    draftCubit.updateScheduleMode(mode);

    if (mode == BranchScheduleMode.custom &&
        draftCubit.state.customSchedule.isEmpty) {
      final companySchedule = context
          .read<AddBranchBloc>()
          .state
          .companySchedule;
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
          autovalidateMode: widget.showValidationErrors
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
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
                  furthestCompletedStep: widget.furthestCompletedStep,
                  onStepTapped: widget.onStepTapped,
                ),
              ),
              _MainInfoSection(
                branchNameController: _branchNameController,
                onPickLocation: widget.onPickLocation,
                showErrors: widget.showValidationErrors,
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
    required this.onPickLocation,
    required this.showErrors,
  });

  final TextEditingController branchNameController;
  final VoidCallback onPickLocation;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

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
                  if (!RequiredValidator.isValid(value)) {
                    return 'branches.add_branch.branch_name_required'.tr();
                  }
                  if (!LengthValidator.isValid(value, maxLength: 255)) {
                    return 'branches.add_branch.branch_name_max_length_error'
                        .tr(namedArgs: {'max': '255'});
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
                      context.read<AddBranchDraftCubit>().updateBranchType(
                        type,
                      );
                    },
                  );
                },
              ),
              SizedBox(height: AppSpacing.md),
              BlocSelector<AddBranchDraftCubit, AddBranchDraft, CityEntity?>(
                selector: (state) => state.selectedCity,
                builder: (context, selectedCity) {
                  return CitySelectField(
                    label: 'branches.add_branch.city'.tr(),
                    hint: 'branches.add_branch.city_select_hint'.tr(),
                    pickerTitle: 'branches.add_branch.city'.tr(),
                    searchHint: 'branches.add_branch.city_search_hint'.tr(),
                    emptyLabel: 'branches.add_branch.city_empty'.tr(),
                    retryLabel: 'common.cancel'.tr(),
                    selectedCity: selectedCity,
                    localizedName: isArabic
                        ? (city) => city.nameAr
                        : (city) => city.nameEn,
                    errorText: showErrors && selectedCity == null
                        ? 'branches.add_branch.city_required'.tr()
                        : null,
                    onCitySelected: (city) {
                      context.read<AddBranchDraftCubit>().updateCity(city);
                    },
                  );
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
                    errorText:
                        showErrors && (address == null || address.isEmpty)
                        ? 'branches.add_branch.location_required'.tr()
                        : null,
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

  String? _phoneValidator(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return null;
    if (!UaePhoneValidator.isValid(phone)) {
      return 'branches.add_branch.invalid_phone'.tr();
    }
    return null;
  }

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
                validator: _phoneValidator,
              ),
              SizedBox(height: AppSpacing.md),
              BlocSelector<
                AddBranchDraftCubit,
                AddBranchDraft,
                BranchManagerEntity?
              >(
                selector: (state) => state.selectedManager,
                builder: (context, selectedManager) {
                  return BranchManagerPickerField(
                    selectedManager: selectedManager,
                    onManagerSelected: (manager) {
                      context.read<AddBranchDraftCubit>().updateManager(
                        manager,
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
                return const Center(child: AppLoadingIndicator());
              }
              return BlocBuilder<AddBranchBloc, AddBranchState>(
                buildWhen: (prev, curr) =>
                    prev.companySchedule != curr.companySchedule,
                builder: (context, blocState) {
                  return BlocSelector<
                    AddBranchDraftCubit,
                    AddBranchDraft,
                    ({
                      BranchScheduleMode mode,
                      List<BranchAvailabilityEntity> customSchedule,
                    })
                  >(
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
