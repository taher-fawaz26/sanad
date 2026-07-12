import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/usecases/get_branch_managers_usecase.dart';
import 'package:branches/src/domain/usecases/get_company_schedule_usecase.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/utils/add_branch_error_snackbar.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:branches/src/presentation/widgets/add_branch_coverage_step.dart';
import 'package:branches/src/presentation/widgets/branch_location_field.dart';
import 'package:branches/src/presentation/widgets/branch_manager_picker_field.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';

/// Figma Add branch wizard — Step 1 (`194:4056`) and Step 2 (`347:13772`).
class AddBranchPage extends StatefulWidget {
  const AddBranchPage({super.key});

  @override
  State<AddBranchPage> createState() => _AddBranchPageState();
}

class _AddBranchPageState extends State<AddBranchPage> {
  static const _totalSteps = 4;

  final _formKey = GlobalKey<FormState>();
  final _branchNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _branchAddress;
  int _currentStep = 1;
  BranchScheduleMode _scheduleMode = BranchScheduleMode.company;
  List<BranchAvailabilityEntity> _companySchedule = const [];
  List<BranchAvailabilityEntity> _customSchedule = const [];
  List<BranchManagerEntity> _managers = const [];
  BranchManagerEntity? _selectedManager;
  bool _isLoadingSetup = true;

  bool get _canProceedStep1 =>
      _branchNameController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty &&
      _branchAddress != null &&
      _selectedManager != null &&
      (_scheduleMode == BranchScheduleMode.company
          ? _companySchedule.isNotEmpty
          : _customSchedule.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _branchNameController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _loadSetupData();
  }

  Future<void> _loadSetupData() async {
    final scheduleResult =
        await sl<GetCompanyScheduleUseCase>()(const NoParams()).run();
    final managersResult =
        await sl<GetBranchManagersUseCase>()(const NoParams()).run();

    if (!mounted) return;

    scheduleResult.fold(
      (_) => setState(() => _isLoadingSetup = false),
      (schedule) {
        final copied = BranchScheduleFormatter.copyAvailability(schedule);
        setState(() {
          _companySchedule = schedule;
          _customSchedule = copied;
          _isLoadingSetup = false;
        });
      },
    );

    managersResult.fold(
      (_) {},
      (managers) {
        if (!mounted) return;
        setState(() {
          _managers = managers;
          _selectedManager = managers.isNotEmpty ? managers.first : null;
        });
      },
    );
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _branchNameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentStep == 1) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      if (_branchAddress == null) {
        showAppSnackbar(
          context: context,
          title: 'branches.add_branch.location_required'.tr(),
        );
        return;
      }
      if (!_canProceedStep1) return;
      setState(() => _currentStep = 2);
    }
  }

  void _onAddLocationPressed() {
    showAppSnackbar(
      context: context,
      title: 'branches.add_branch.add_location_coming_soon'.tr(),
    );
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
          showAddBranchErrorSnackbar(
            context: context,
            failure: state.failure!,
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
                child: _currentStep == 1
                    ? _buildStepOne()
                    : _buildStepTwo(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: BlocBuilder<AddBranchBloc, AddBranchState>(
                  builder: (context, state) {
                    if (_currentStep == 1) {
                      return AppButton(
                        label: 'branches.add_branch.next_button'.tr(),
                        isLoading: state.isLoading,
                        onPressed: state.isLoading || _isNextDisabled
                            ? null
                            : _onNextPressed,
                      );
                    }

                    return AppButton(
                      label: 'branches.add_branch.add_location_button'.tr(),
                      onPressed: _onAddLocationPressed,
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

  bool get _isNextDisabled {
    if (_currentStep == 1) {
      return _isLoadingSetup || !_canProceedStep1;
    }
    return false;
  }

  Widget _buildStepOne() {
    return SingleChildScrollView(
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
                currentStep: _currentStep,
                totalSteps: _totalSteps,
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
                    onActionTap: () {
                      // TODO(branches): integrate map picker
                      setState(() {
                        _branchAddress =
                            _cityController.text.trim().isNotEmpty
                            ? _cityController.text.trim()
                            : 'Address';
                      });
                    },
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
              child: _isLoadingSetup
                  ? const Center(child: CircularProgressIndicator())
                  : BranchScheduleSection(
                      mode: _scheduleMode,
                      companySchedule: _companySchedule,
                      customSchedule: _customSchedule,
                      onModeChanged: _onScheduleModeChanged,
                      onCustomScheduleChanged: (schedule) {
                        setState(() => _customSchedule = schedule);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTwo() {
    return Column(
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
            currentStep: _currentStep,
            totalSteps: _totalSteps,
          ),
        ),
        Expanded(
          child: AddBranchCoverageStep(
            onAddLocation: _onAddLocationPressed,
          ),
        ),
      ],
    );
  }
}
