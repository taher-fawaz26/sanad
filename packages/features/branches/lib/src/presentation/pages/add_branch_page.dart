import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/models/coverage_area_args.dart';
import 'package:branches/src/presentation/models/coverage_area_result.dart';
import 'package:branches/src/presentation/models/step_one_data.dart';
import 'package:branches/src/presentation/utils/add_branch_error_snackbar.dart';
import 'package:branches/src/presentation/utils/add_branch_submit_helper.dart';
import 'package:branches/src/presentation/widgets/add_branch_coverage_step.dart';
import 'package:branches/src/presentation/widgets/add_branch_services_step.dart';
import 'package:branches/src/presentation/widgets/add_branch_step_one.dart';
import 'package:branches/src/presentation/widgets/add_branch_workers_step.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

/// Figma Add branch wizard — Step 1 (`194:4056`) and Step 2 (`347:13772` / `972:9206`).
class AddBranchPage extends StatefulWidget {
  const AddBranchPage({super.key});

  @override
  State<AddBranchPage> createState() => _AddBranchPageState();
}

class _AddBranchPageState extends State<AddBranchPage> {
  static const _totalSteps = 4;

  final _stepOneKey = GlobalKey<AddBranchStepOneState>();
  final _canProceedStep1 = ValueNotifier<bool>(false);

  int _currentStep = 1;
  StepOneData? _stepOneSnapshot;

  // Steps 2–4 state stays in the page since these steps are lightweight.
  String? _branchAddress;
  LatLng? _pickedPosition;
  double? _coverageRadiusKm;
  List<ServingArea> _servingAreas = const [];
  List<ServiceEntity> _selectedServices = const [];
  List<WorkerEntity> _selectedWorkers = const [];

  bool get _hasCoverage =>
      _coverageRadiusKm != null &&
      _branchAddress != null &&
      _branchAddress!.isNotEmpty;

  bool get _hasServices => _selectedServices.isNotEmpty;

  bool get _hasWorkers => _selectedWorkers.isNotEmpty;

  @override
  void dispose() {
    _canProceedStep1.dispose();
    super.dispose();
  }

  // ── Navigation ──

  void _onNextPressed() {
    if (_currentStep == 1) {
      final stepOne = _stepOneKey.currentState;
      if (stepOne == null) return;
      if (!stepOne.validateForm()) return;
      if (!_canProceedStep1.value) return;

      final data = stepOne.collectData();
      _branchAddress ??= data.branchAddress;
      _pickedPosition ??= data.pickedPosition;

      setState(() {
        _stepOneSnapshot = data;
        _currentStep = 2;
      });
      return;
    }

    if (_currentStep == 2 && _hasCoverage) {
      setState(() => _currentStep = 3);
      return;
    }

    if (_currentStep == 3 && _hasServices) {
      setState(() => _currentStep = 4);
    }
  }

  void _submit() {
    final snapshot = _stepOneSnapshot;
    if (snapshot == null) return;

    final params = buildCreateBranchParams(
      stepOne: snapshot,
      branchAddress: _branchAddress,
      pickedPosition: _pickedPosition,
      coverageRadiusKm: _coverageRadiusKm,
      servingAreas: _servingAreas,
      selectedServices: _selectedServices,
      selectedWorkers: _selectedWorkers,
    );

    context.read<AddBranchBloc>().add(AddBranchSubmitEvent(params: params));
  }

  // ── Location / Coverage ──

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

    // Update step 1 internal state if it's still mounted.
    _stepOneKey.currentState?.updateLocation(
      address: result.address,
      position: result.position,
    );

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
        servingAreas: _servingAreas,
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      _branchAddress = result.address;
      _pickedPosition = result.position;
      _coverageRadiusKm = result.radiusKm;
      _servingAreas = result.servingAreas;
    });
  }

  // ── Services / Workers ──

  Future<void> _openSelectServices() async {
    final result = await showSelectServiceActionSheet(
      context: context,
      initialSelectedIds: _selectedServices.map((s) => s.id).toSet(),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedServices = result.selectedServices);
  }

  Future<void> _openSelectWorkers() async {
    final result = await showSelectWorkerActionSheet(
      context: context,
      initialSelectedIds: _selectedWorkers.map((w) => w.id).toSet(),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedWorkers = result.selectedWorkers);
  }

  void _onRemoveWorker(WorkerEntity worker) {
    setState(
      () => _selectedWorkers =
          _selectedWorkers.where((w) => w.id != worker.id).toList(),
    );
  }

  // ── Success popover ──

  void _showBranchCreatedSuccessPopover() {
    final colors = context.appColors;
    final spec = context.appDialogTheme.spec;

    showAppPopover<void>(
      context: context,
      title: '',
      titleWidget: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'branches.add_branch.success_dialog_title_highlight'.tr(),
              style: spec.titleStyle.copyWith(color: colors.primary),
            ),
            TextSpan(
              text: 'branches.add_branch.success_dialog_title_body'.tr(),
              style: spec.titleStyle,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      description: 'branches.add_branch.success_dialog_description'.tr(),
      imageLayout: AppDialogImageLayout.iconSmall,
      featureIconColor: AppFeatureIconColor.success,
      actions: AppPopoverActions.single,
      primaryLabel: 'branches.add_branch.success_dialog_okay'.tr(),
      barrierDismissible: false,
    ).then((_) {
      if (mounted) context.pop();
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddBranchBloc, AddBranchState>(
      listener: (context, state) {
        if (state.isSuccess) {
          _showBranchCreatedSuccessPopover();
        } else if (state.hasError && state.failure != null) {
          showAddBranchErrorSnackbar(
            context: context,
            failure: state.failure!,
          );
        } else if (state.hasSetupError && state.setupFailure != null) {
          showAddBranchErrorSnackbar(
            context: context,
            failure: state.setupFailure!,
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
              Expanded(child: _buildCurrentStep()),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: _buildBottomButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_currentStep) {
      1 => AddBranchStepOne(
          key: _stepOneKey,
          canProceed: _canProceedStep1,
          onPickLocation: _pickLocation,
          currentStep: _currentStep,
          totalSteps: _totalSteps,
        ),
      2 => _WizardStepShell(
          currentStep: _currentStep,
          totalSteps: _totalSteps,
          caption: _hasCoverage
              ? 'branches.add_branch.coverage_set_title'.tr()
              : 'branches.add_branch.coverage_step_subtitle'.tr(),
          child: AddBranchCoverageStep(
            pickedAddress: _branchAddress,
            servingAreas: _servingAreas,
            radiusKm: _coverageRadiusKm,
            onEditCoverage: _openCoverageArea,
          ),
        ),
      3 => _WizardStepShell(
          currentStep: _currentStep,
          totalSteps: _totalSteps,
          caption: 'branches.add_branch.services_step_subtitle'.tr(),
          child: AddBranchServicesStep(
            selectedServices: _selectedServices,
            onAddServices: _openSelectServices,
          ),
        ),
      4 => _WizardStepShell(
          currentStep: _currentStep,
          totalSteps: _totalSteps,
          caption: 'branches.add_branch.workers_step_subtitle'.tr(),
          child: AddBranchWorkersStep(
            selectedWorkers: _selectedWorkers,
            onAddWorkers: _openSelectWorkers,
            onRemoveWorker: _onRemoveWorker,
          ),
        ),
      _ => _WizardStepShell(
          currentStep: _currentStep,
          totalSteps: _totalSteps,
          caption: 'branches.add_branch.subtitle'.tr(),
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
    };
  }

  Widget _buildBottomButton() {
    if (_currentStep == 1) {
      return ValueListenableBuilder<bool>(
        valueListenable: _canProceedStep1,
        builder: (context, canProceed, _) {
          return BlocSelector<AddBranchBloc, AddBranchState,
              ({bool isLoading, bool isLoadingSetup})>(
            selector: (state) => (
              isLoading: state.isLoading,
              isLoadingSetup: state.isLoadingSetup,
            ),
            builder: (context, rec) {
              final disabled = rec.isLoadingSetup || !canProceed;
              return AppButton(
                label: 'branches.add_branch.next_button'.tr(),
                isLoading: rec.isLoading,
                onPressed: rec.isLoading || disabled ? null : _onNextPressed,
              );
            },
          );
        },
      );
    }

    if (_currentStep == 2) {
      if (!_hasCoverage) {
        return AppButton(
          label: 'branches.add_branch.add_location_button'.tr(),
          onPressed: _openCoverageArea,
        );
      }
      return AppButton(
        label: 'branches.add_branch.next_button'.tr(),
        onPressed: _onNextPressed,
      );
    }

    if (_currentStep == 3) {
      if (!_hasServices) {
        return AppButton(
          label: 'branches.add_branch.add_services_button'.tr(),
          onPressed: _openSelectServices,
        );
      }
      return AppButton(
        label: 'branches.add_branch.next_button'.tr(),
        onPressed: _onNextPressed,
      );
    }

    if (_currentStep == 4) {
      if (!_hasWorkers) {
        return AppButton(
          label: 'branches.add_branch.add_workers_button'.tr(),
          onPressed: _openSelectWorkers,
        );
      }
      return BlocSelector<AddBranchBloc, AddBranchState, bool>(
        selector: (state) => state.isLoading,
        builder: (context, isLoading) {
          return AppButton(
            label: 'branches.add_branch.save_button'.tr(),
            isLoading: isLoading,
            onPressed: isLoading ? null : _submit,
          );
        },
      );
    }

    return BlocSelector<AddBranchBloc, AddBranchState, bool>(
      selector: (state) => state.isLoading,
      builder: (context, isLoading) {
        return AppButton(
          label: 'branches.add_branch.save_button'.tr(),
          isLoading: isLoading,
          onPressed: isLoading ? null : _submit,
        );
      },
    );
  }
}

/// Shared chrome for steps 2–4: title bar + step indicator + expanded content.
class _WizardStepShell extends StatelessWidget {
  const _WizardStepShell({
    required this.currentStep,
    required this.totalSteps,
    required this.caption,
    required this.child,
  });

  final int currentStep;
  final int totalSteps;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLargeNavBar(
          title: 'branches.add_branch.title'.tr(),
          caption: caption,
          useLargeTitleStyle: false,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: AppWizardStepIndicator(
            currentStep: currentStep,
            totalSteps: totalSteps,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
