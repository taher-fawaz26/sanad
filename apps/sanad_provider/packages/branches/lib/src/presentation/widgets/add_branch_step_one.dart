import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_schedule_mode.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    final draft = context.read<AddBranchDraftBloc>().state;
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
    context.read<AddBranchDraftBloc>().updateBasicInfo(
      branchName: _branchNameController.text,
      phone: _phoneController.text,
    );
  }

  /// The widget-level "have we already seeded" latch is gone — both
  /// [AddBranchDraftBloc.setCompanyHasWorkingHours] and
  /// [AddBranchDraftBloc.initializeCustomSchedule] are idempotent (the
  /// former no-ops on equal value, the latter no-ops when a custom schedule
  /// already exists), so it is safe to call them on every setup-success
  /// transition.
  void _seedFromSetup(AddBranchState state) {
    if (state.setupStatus != RequestStatus.success) return;
    context.read<AddBranchDraftBloc>()
      ..setCompanyHasWorkingHours(
        hasHours: state.companySchedule.any((day) => day.slots.isNotEmpty),
      )
      ..initializeCustomSchedule(
        BranchScheduleFormatter.copyAvailability(state.companySchedule),
      );
  }

  void _onScheduleModeChanged(BranchScheduleMode mode) {
    final draftCubit = context.read<AddBranchDraftBloc>();
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
              _ContactSection(
                phoneController: _phoneController,
                showErrors: widget.showValidationErrors,
              ),
              const AppDivider(thickness: AppDividerThickness.thick),
              _WorkingHoursSection(
                onScheduleModeChanged: _onScheduleModeChanged,
                showErrors: widget.showValidationErrors,
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
                isRequired: true,
                validator: (value) {
                  if (!RequiredValidator.isValid(value)) {
                    return 'branches.add_branch.branch_name_required'.tr();
                  }
                  if (!MeaningfulTextValidator.isValid(value)) {
                    return 'validation.invalid_name'.tr();
                  }
                  if (!LengthValidator.isValid(value, maxLength: 255)) {
                    return 'branches.add_branch.branch_name_max_length_error'
                        .tr(namedArgs: {'max': '255'});
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.md),
              BlocSelector<AddBranchDraftBloc, AddBranchDraft, BranchType>(
                selector: (state) => state.branchType,
                builder: (context, selectedType) {
                  return BranchTypeSelectField(
                    selectedType: selectedType,
                    isRequired: true,
                    onTypeSelected: (type) {
                      context.read<AddBranchDraftBloc>().updateBranchType(
                        type,
                      );
                    },
                  );
                },
              ),
              SizedBox(height: AppSpacing.md),
              BlocSelector<
                AddBranchDraftBloc,
                AddBranchDraft,
                ({String? address, bool hasPlaceId})
              >(
                selector: (state) => (
                  address: state.branchAddress,
                  hasPlaceId: state.locationPlaceId != null,
                ),
                builder: (context, location) {
                  final address = location.address;
                  final isEmpty = address == null || address.isEmpty;
                  return BranchLocationField(
                    label: 'branches.add_branch.location'.tr(),
                    value: address,
                    hint: 'branches.add_branch.location_hint'.tr(),
                    actionLabel: 'branches.add_branch.location_set'.tr(),
                    isRequired: true,
                    // An address without a Place ID (dragged pin / GPS) is
                    // rejected by branch creation, so flag it and point the
                    // user back to search. Shown unconditionally (not just
                    // after a Next attempt) because Next stays disabled while
                    // Step 1 is incomplete — so the failed-Next reveal never
                    // fires, and the location would otherwise look filled in
                    // with no reason given for the disabled button.
                    errorText: isEmpty
                        ? (showErrors
                              ? 'branches.add_branch.location_required'.tr()
                              : null)
                        : location.hasPlaceId
                        ? null
                        : 'branches.add_branch'
                                  '.location_select_from_search'
                              .tr(),
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
  const _ContactSection({
    required this.phoneController,
    required this.showErrors,
  });

  final TextEditingController phoneController;
  final bool showErrors;

  String? _phoneValidator(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return 'validation.required'.tr();
    return UaePhoneValidator.mobileValidationMessage(phone)?.tr();
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
                isRequired: true,
                validator: _phoneValidator,
                // Validate live as the user types (not only after a failed
                // "Next") so an invalid number (wrong prefix / repeated
                // digits) surfaces an error immediately instead of sitting in
                // the field with a valid-looking border (SAN-777). The field
                // already caps input at 10 digits and requires a UAE mobile.
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              SizedBox(height: AppSpacing.md),
              BlocSelector<
                AddBranchDraftBloc,
                AddBranchDraft,
                BranchManagerEntity?
              >(
                selector: (state) => state.selectedManager,
                builder: (context, selectedManager) {
                  return BranchManagerPickerField(
                    selectedManager: selectedManager,
                    isRequired: true,
                    errorText: showErrors && selectedManager == null
                        ? 'branches.add_branch.branch_manager_required'.tr()
                        : null,
                    onManagerSelected: (manager) {
                      context.read<AddBranchDraftBloc>().updateManager(
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
  const _WorkingHoursSection({
    required this.onScheduleModeChanged,
    required this.showErrors,
  });

  final ValueChanged<BranchScheduleMode> onScheduleModeChanged;
  final bool showErrors;

  /// Localized schedule error for the current draft, or `null` when the
  /// working hours are valid. Company mode requires the company to actually
  /// have hours to inherit; custom mode requires at least one added slot.
  String? _scheduleError(
    ({
      BranchScheduleMode mode,
      List<BranchAvailabilityEntity> customSchedule,
      bool companyHasWorkingHours,
      ScheduleSlotRejection? rejection,
    })
    draft,
  ) {
    switch (draft.mode) {
      case BranchScheduleMode.company:
        if (draft.companyHasWorkingHours) return null;
        return 'branches.add_branch.schedule_company_empty'.tr();
      case BranchScheduleMode.custom:
        final hasHours = draft.customSchedule.any(
          (day) => day.slots.isNotEmpty,
        );
        if (hasHours) return null;
        return 'branches.add_branch.schedule_required'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.add_branch.section_working_hours'.tr(),
          size: AppSectionSize.compact,
          tone: AppSectionTone.primary,
          isRequired: true,
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
                    AddBranchDraftBloc,
                    AddBranchDraft,
                    ({
                      BranchScheduleMode mode,
                      List<BranchAvailabilityEntity> customSchedule,
                      bool companyHasWorkingHours,
                      ScheduleSlotRejection? rejection,
                    })
                  >(
                    selector: (state) => (
                      mode: state.scheduleMode,
                      customSchedule: state.customSchedule,
                      companyHasWorkingHours: state.companyHasWorkingHours,
                      rejection: state.lastScheduleRejection,
                    ),
                    builder: (context, draft) {
                      final draftCubit = context.read<AddBranchDraftBloc>();
                      final scheduleError = showErrors
                          ? _scheduleError(draft)
                          : null;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BranchScheduleSection(
                            mode: draft.mode,
                            companySchedule: blocState.companySchedule,
                            customSchedule: draft.customSchedule,
                            rejection: draft.rejection,
                            onModeChanged: onScheduleModeChanged,
                            onAddSlot: (dayId, from, to) =>
                                draftCubit.addScheduleSlot(
                                  dayId: dayId,
                                  from: from,
                                  to: to,
                                ),
                            onRemoveSlot: draftCubit.removeScheduleSlot,
                          ),
                          if (scheduleError != null) ...[
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              scheduleError,
                              style: context.appTypography.smallNormal.copyWith(
                                color: context.appColors.error,
                              ),
                            ),
                          ],
                        ],
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
