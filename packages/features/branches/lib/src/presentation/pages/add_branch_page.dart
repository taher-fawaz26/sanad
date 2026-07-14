import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/models/coverage_area_args.dart';
import 'package:branches/src/presentation/models/coverage_area_result.dart';
import 'package:branches/src/presentation/utils/add_branch_error_snackbar.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:branches/src/presentation/widgets/add_branch_coverage_step.dart';
import 'package:branches/src/presentation/widgets/branch_location_field.dart';
import 'package:branches/src/presentation/widgets/branch_manager_picker_field.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:maps/maps.dart';

/// Figma Add branch wizard — Step 1 (`194:4056`) and Step 2 (`347:13772` / `972:9206`).
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
  LatLng? _pickedPosition;
  double? _coverageRadiusKm;
  List<String> _coveredAreas = const [];
  int _currentStep = 1;
  BranchScheduleMode _scheduleMode = BranchScheduleMode.company;
  List<BranchAvailabilityEntity> _companySchedule = const [];
  List<BranchAvailabilityEntity> _customSchedule = const [];
  List<BranchManagerEntity> _managers = const [];
  BranchManagerEntity? _selectedManager;

  /// Guards a one-time seed of the editable form fields from bloc setup data.
  bool _setupSeeded = false;

  bool get _isLoadingSetup =>
      context.watch<AddBranchBloc>().state.isLoadingSetup;

  bool get _hasCoverage =>
      _coverageRadiusKm != null &&
      _branchAddress != null &&
      _branchAddress!.isNotEmpty;

  bool get _canProceedStep1 =>
      _branchNameController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty &&
      _branchAddress != null &&
      _pickedPosition != null &&
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
  }

  /// Copies bloc-loaded setup data into the editable form state exactly once.
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
      // The Next button is already disabled until step 1 is complete
      // (see [_isNextDisabled]); this guards against a stale tap.
      if (!_canProceedStep1) return;
      setState(() => _currentStep = 2);
      return;
    }

    if (_currentStep == 2 && _hasCoverage) {
      // Steps 3–4 (services / team) are not implemented yet; keep coverage
      // and continue the wizard shell so the 4-step indicator stays accurate.
      setState(() => _currentStep = 3);
    }
  }

  void _submit() {
    final position = _pickedPosition;
    final schedule = _scheduleMode == BranchScheduleMode.company
        ? _companySchedule
        : _customSchedule;

    context.read<AddBranchBloc>().add(
          AddBranchSubmitEvent(
            params: CreateBranchParams(
              branchName: _branchNameController.text.trim(),
              branchAddress: _branchAddress ?? '',
              city: _cityController.text.trim(),
              branchPhone: _phoneController.text.trim(),
              branchManagerId: _selectedManager?.id,
              lat: position?.latitude,
              lng: position?.longitude,
              radiusKm: _coverageRadiusKm,
              availability: schedule,
            ),
          ),
        );
  }

  Future<void> _pickLocation() async {
    final result = await showLocationPickerSheet(
      context,
      labels: LocationPickerLabels(
        searchHint: 'branches.location_picker.search_hint'.tr(),
        confirm: 'branches.location_picker.confirm'.tr(),
        specifiedLocation:
            'branches.location_picker.specified_location'.tr(),
        addressHint: 'branches.location_picker.address_hint'.tr(),
        permissionDenied:
            'branches.location_picker.permission_denied'.tr(),
        permissionPermanentlyDenied: 'branches.location_picker'
            '.permission_permanently_denied'
            .tr(),
        serviceDisabled:
            'branches.location_picker.service_disabled'.tr(),
        genericError: 'branches.location_picker.generic_error'.tr(),
        openSettings: 'branches.location_picker.open_settings'.tr(),
      ),
      initialPosition: _pickedPosition,
      initialAddress: _branchAddress,
    );
    if (!mounted || result == null) return;

    setState(() {
      _branchAddress = result.address;
      _pickedPosition = result.position;
    });
  }

  Future<void> _openCoverageArea() async {
    final result = await context.push<CoverageAreaResult>(
      BranchRoutes.coverage,
      extra: CoverageAreaArgs(
        position: _pickedPosition,
        address: _branchAddress,
        radiusKm: _coverageRadiusKm,
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      _branchAddress = result.address;
      _pickedPosition = result.position;
      _coverageRadiusKm = result.radiusKm;
      _coveredAreas = result.coveredAreas;
    });
  }

  void _onAddLocationPressed() {
    _openCoverageArea();
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
        _seedFromSetup(state);
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
                child: switch (_currentStep) {
                  1 => _buildStepOne(),
                  2 => _buildStepTwo(),
                  _ => _buildUpcomingStepPlaceholder(),
                },
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

                    if (_currentStep == 2) {
                      if (!_hasCoverage) {
                        return AppButton(
                          label:
                              'branches.add_branch.add_location_button'.tr(),
                          onPressed: _onAddLocationPressed,
                        );
                      }
                      return AppButton(
                        label: 'branches.add_branch.next_button'.tr(),
                        onPressed: _onNextPressed,
                      );
                    }

                    return AppButton(
                      label: 'branches.add_branch.save_button'.tr(),
                      isLoading: state.isLoading,
                      onPressed: state.isLoading ? null : _submit,
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
                    onActionTap: _pickLocation,
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
    final hasCoverage = _hasCoverage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLargeNavBar(
          title: 'branches.add_branch.title'.tr(),
          caption: hasCoverage
              ? 'branches.add_branch.coverage_set_title'.tr()
              : 'branches.add_branch.coverage_step_subtitle'.tr(),
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
            pickedAddress: _branchAddress,
            coveredAreas: _coveredAreas,
            radiusKm: _coverageRadiusKm,
            onEditCoverage: _onAddLocationPressed,
          ),
        ),
      ],
    );
  }

  /// Temporary shell for steps 3–4 until their Figma screens are wired.
  Widget _buildUpcomingStepPlaceholder() {
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
          child: Center(
            child: Text(
              'branches.add_branch.upcoming_step_placeholder'.tr(),
              textAlign: TextAlign.center,
              style: context.appTypography.regularNormal.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
