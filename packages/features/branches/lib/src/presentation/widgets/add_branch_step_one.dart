import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/models/step_one_data.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:branches/src/presentation/widgets/branch_location_field.dart';
import 'package:branches/src/presentation/widgets/branch_manager_picker_field.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:maps/maps.dart';

class AddBranchStepOne extends StatefulWidget {
  const AddBranchStepOne({
    required this.canProceed,
    required this.onPickLocation,
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  final ValueNotifier<bool> canProceed;
  final VoidCallback onPickLocation;
  final int currentStep;
  final int totalSteps;

  @override
  State<AddBranchStepOne> createState() => AddBranchStepOneState();
}

class AddBranchStepOneState extends State<AddBranchStepOne> {
  final _formKey = GlobalKey<FormState>();
  final _branchNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _branchAddress;
  LatLng? _pickedPosition;
  BranchScheduleMode _scheduleMode = BranchScheduleMode.company;
  List<BranchAvailabilityEntity> _companySchedule = const [];
  List<BranchAvailabilityEntity> _customSchedule = const [];
  List<BranchManagerEntity> _managers = const [];
  BranchManagerEntity? _selectedManager;

  bool _setupSeeded = false;

  @override
  void initState() {
    super.initState();
    _branchNameController.addListener(_recomputeCanProceed);
    _cityController.addListener(_recomputeCanProceed);
    _phoneController.addListener(_recomputeCanProceed);
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _recomputeCanProceed() {
    final canProceed =
        _branchNameController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _branchAddress != null &&
        _pickedPosition != null &&
        _selectedManager != null &&
        (_scheduleMode == BranchScheduleMode.company
            ? _companySchedule.isNotEmpty
            : _customSchedule.isNotEmpty);
    widget.canProceed.value = canProceed;
  }

  void _seedFromSetup(AddBranchState state) {
    if (_setupSeeded || state.setupStatus != RequestStatus.success) return;
    _setupSeeded = true;
    setState(() {
      _companySchedule = state.companySchedule;
      _customSchedule =
          BranchScheduleFormatter.copyAvailability(state.companySchedule);
      _managers = state.managers;
      _selectedManager =
          state.managers.isNotEmpty ? state.managers.first : null;
    });
    _recomputeCanProceed();
  }

  bool validateForm() => _formKey.currentState?.validate() ?? false;

  StepOneData collectData() {
    final isCustom = _scheduleMode == BranchScheduleMode.custom;
    return StepOneData(
      branchName: _branchNameController.text.trim(),
      city: _cityController.text.trim(),
      phone: _phoneController.text.trim(),
      branchAddress: _branchAddress,
      pickedPosition: _pickedPosition,
      managerId: _selectedManager?.id,
      isCustomSchedule: isCustom,
      schedule: isCustom ? _customSchedule : _companySchedule,
    );
  }

  void updateLocation({required String? address, required LatLng? position}) {
    setState(() {
      _branchAddress = address;
      _pickedPosition = position;
    });
    _recomputeCanProceed();
  }

  void _onScheduleModeChanged(BranchScheduleMode mode) {
    setState(() {
      _scheduleMode = mode;
      if (mode == BranchScheduleMode.custom &&
          _customSchedule.isEmpty &&
          _companySchedule.isNotEmpty) {
        _customSchedule =
            BranchScheduleFormatter.copyAvailability(_companySchedule);
      }
    });
    _recomputeCanProceed();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddBranchBloc, AddBranchState>(
      listenWhen: (prev, curr) => prev.setupStatus != curr.setupStatus,
      listener: (_, state) => _seedFromSetup(state),
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
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: AppWizardStepIndicator(
                  currentStep: widget.currentStep,
                  totalSteps: widget.totalSteps,
                ),
              ),
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
                      controller: _branchNameController,
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
                      actionLabel: 'branches.add_branch.location_set'.tr(),
                      onActionTap: widget.onPickLocation,
                    ),
                  ],
                ),
              ),
              const AppDivider(thickness: AppDividerThickness.thick),
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
                      controller: _phoneController,
                      hint: 'branches.add_branch.branch_phone_hint'.tr(),
                    ),
                    SizedBox(height: AppSpacing.md),
                    BranchManagerPickerField(
                      managers: _managers,
                      selectedManager: _selectedManager,
                      onManagerSelected: (manager) {
                        setState(() => _selectedManager = manager);
                        _recomputeCanProceed();
                      },
                    ),
                  ],
                ),
              ),
              const AppDivider(thickness: AppDividerThickness.thick),
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
                    return BranchScheduleSection(
                      mode: _scheduleMode,
                      companySchedule: _companySchedule,
                      customSchedule: _customSchedule,
                      onModeChanged: _onScheduleModeChanged,
                      onCustomScheduleChanged: (schedule) {
                        setState(() => _customSchedule = schedule);
                        _recomputeCanProceed();
                      },
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
