import 'dart:async';

import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:core/core.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/models/coverage_area_args.dart';
import 'package:branches/src/presentation/models/coverage_area_result.dart';
import 'package:branches/src/presentation/utils/add_branch_error_snackbar.dart';
import 'package:branches/src/presentation/utils/add_branch_params_mapper.dart';
import 'package:branches/src/presentation/utils/branch_dialogs.dart';
import 'package:branches/src/presentation/widgets/add_branch_coverage_step.dart';
import 'package:branches/src/presentation/widgets/add_branch_review_step.dart';
import 'package:branches/src/presentation/widgets/add_branch_services_step.dart';
import 'package:branches/src/presentation/widgets/add_branch_step_one.dart';
import 'package:branches/src/presentation/widgets/add_branch_wizard_footer.dart';
import 'package:branches/src/presentation/widgets/add_branch_wizard_step_shell.dart';
import 'package:branches/src/presentation/widgets/add_branch_workers_step.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:maps/maps.dart';
import 'package:permissions/permissions.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

class AddBranchPage extends StatefulWidget {
  const AddBranchPage({super.key});

  @override
  State<AddBranchPage> createState() => _AddBranchPageState();
}

class _AddBranchPageState extends State<AddBranchPage> {
  static const _totalSteps = 5;

  final _stepOneFormKey = GlobalKey<FormState>();
  int _currentStep = 1;
  int _furthestStep = 1;
  bool _locationPermissionDenied = false;
  bool _stepOneShowErrors = false;

  Future<bool> _handleCloseRequest() async {
    final draft = context.read<AddBranchDraftCubit>().state;
    if (!draft.isDirty) return true;

    final shouldDiscard = await showDiscardBranchChangesDialog(context);
    return shouldDiscard ?? false;
  }

  Future<void> _onCloseTapped() async {
    if (await _handleCloseRequest()) {
      if (mounted) context.pop();
    }
  }

  void _advanceTo(int step) {
    setState(() {
      _currentStep = step;
      if (step > _furthestStep) _furthestStep = step;
    });
  }

  void _onStepTapped(int step) {
    if (step <= _furthestStep) {
      setState(() => _currentStep = step);
    }
  }

  void _onNextPressed() {
    if (_currentStep == 1) {
      setState(() => _stepOneShowErrors = true);
      final formValid = _stepOneFormKey.currentState?.validate() ?? false;
      final draft = context.read<AddBranchDraftCubit>().state;
      if (!formValid || !draft.isStepOneComplete) return;
      if (draft.phone.trim().isNotEmpty &&
          !UaePhoneValidator.isValid(draft.phone)) {
        return;
      }
      setState(() => _stepOneShowErrors = false);
      _advanceTo(2);
      return;
    }

    final draft = context.read<AddBranchDraftCubit>().state;

    if (_currentStep == 2 && draft.isStepTwoComplete) {
      _advanceTo(3);
      return;
    }

    if (_currentStep == 3 && draft.isStepThreeComplete) {
      _advanceTo(4);
      return;
    }

    if (_currentStep == 4 && draft.isStepFourComplete) {
      _advanceTo(5);
    }
  }

  Future<void> _submit() async {
    final draft = context.read<AddBranchDraftCubit>().state;
    final companySchedule = context.read<AddBranchBloc>().state.companySchedule;

    final params = AddBranchParamsMapper.toCreateParams(
      draft,
      companySchedule: companySchedule,
    );

    if (!mounted) return;
    unawaited(showBranchSubmitLoadingDialog(context));

    context.read<AddBranchBloc>().add(AddBranchSubmitEvent(params: params));
  }

  Future<void> _pickLocation() async {
    final permissionResult = await sl<PermissionsService>().request(
      Permission.locationWhenInUse,
    );

    if (!mounted) return;

    if (permissionResult != PermissionRequestResult.granted) {
      setState(() => _locationPermissionDenied = true);
      return;
    }

    setState(() => _locationPermissionDenied = false);

    final draft = context.read<AddBranchDraftCubit>().state;
    final result = await showLocationPickerSheet(
      context,
      labels: LocationPickerLabels(
        searchHint: 'branches.location_picker.search_hint'.tr(),
        confirm: 'branches.location_picker.confirm'.tr(),
        specifiedLocation: 'branches.location_picker.specified_location'.tr(),
        addressHint: 'branches.location_picker.address_hint'.tr(),
        permissionDenied: 'branches.location_picker.permission_denied'.tr(),
        permissionPermanentlyDenied:
            'branches.location_picker.permission_permanently_denied'.tr(),
        serviceDisabled: 'branches.location_picker.service_disabled'.tr(),
        genericError: 'branches.location_picker.generic_error'.tr(),
        openSettings: 'branches.location_picker.open_settings'.tr(),
      ),
      initialPosition: draft.pickedPosition,
      initialAddress: draft.branchAddress,
    );
    if (!mounted || result == null) return;

    context.read<AddBranchDraftCubit>().updateLocation(
      address: result.address,
      position: result.position,
    );
  }

  Future<void> _openLocationSettings() async {
    await sl<PermissionsService>().openSettings();
    if (!mounted) return;
    setState(() => _locationPermissionDenied = false);
    await _pickLocation();
  }

  Future<void> _openCoverageArea() async {
    final draft = context.read<AddBranchDraftCubit>().state;
    final result = await context.push<CoverageAreaResult>(
      BranchRoutes.coverage,
      extra: CoverageAreaArgs(
        position: draft.pickedPosition,
        address: draft.branchAddress,
        radiusKm: draft.coverageRadiusKm,
        servingAreas: draft.servingAreas,
        cityId: draft.selectedCity?.id,
      ),
    );
    if (!mounted || result == null) return;

    context.read<AddBranchDraftCubit>().updateCoverage(
      address: result.address,
      position: result.position,
      radiusKm: result.radiusKm,
      servingAreas: result.servingAreas,
    );
  }

  Future<void> _openSelectServices() async {
    final draft = context.read<AddBranchDraftCubit>().state;
    final result = await showSelectServiceActionSheet(
      context: context,
      initialSelectedIds: draft.selectedServices.map((s) => s.id).toSet(),
    );
    if (!mounted || result == null) return;
    context.read<AddBranchDraftCubit>().updateServices(result.selectedServices);
  }

  Future<void> _openSelectWorkers() async {
    final draft = context.read<AddBranchDraftCubit>().state;
    final result = await showSelectWorkerActionSheet(
      context: context,
      initialSelectedIds: draft.selectedWorkers.map((w) => w.id).toSet(),
    );
    if (!mounted || result == null) return;
    context.read<AddBranchDraftCubit>().updateWorkers(result.selectedWorkers);
  }

  void _onBlocStateChanged(BuildContext context, AddBranchState state) {
    if (state.isSuccess) {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showBranchCreatedSuccessPopover();
    } else if (state.hasError && state.failure != null) {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
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
  }

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _handleCloseRequest()) {
          if (context.mounted) context.pop();
        }
      },
      child: BlocListener<AddBranchBloc, AddBranchState>(
        listener: _onBlocStateChanged,
        child: Scaffold(
          backgroundColor: context.appColors.surface,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppNavBar(
                  title: '',
                  leading: AppCloseIcon(onTap: _onCloseTapped),
                ),
                Expanded(child: _buildCurrentStep()),
                AddBranchWizardFooter(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  onNext: _onNextPressed,
                  onSubmit: _submit,
                  onAddCoverage: _openCoverageArea,
                  onAddServices: _openSelectServices,
                  onAddWorkers: _openSelectWorkers,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_currentStep) {
      1 => AddBranchStepOne(
        formKey: _stepOneFormKey,
        onPickLocation: _pickLocation,
        currentStep: _currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: _furthestStep,
        onStepTapped: _onStepTapped,
        locationPermissionDenied: _locationPermissionDenied,
        onOpenLocationSettings: _openLocationSettings,
        onRetryLocation: _pickLocation,
        showValidationErrors: _stepOneShowErrors,
      ),
      2 => AddBranchWizardStepShell(
        currentStep: _currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: _furthestStep,
        onStepTapped: _onStepTapped,
        child:
            BlocSelector<
              AddBranchDraftCubit,
              AddBranchDraft,
              ({
                String? address,
                List<ServingArea> areas,
                double? radius,
              })
            >(
              selector: (state) => (
                address: state.branchAddress,
                areas: state.servingAreas,
                radius: state.coverageRadiusKm,
              ),
              builder: (context, data) {
                return AddBranchCoverageStep(
                  pickedAddress: data.address,
                  servingAreas: data.areas,
                  radiusKm: data.radius,
                  onEditCoverage: _openCoverageArea,
                );
              },
            ),
      ),
      3 => AddBranchWizardStepShell(
        currentStep: _currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: _furthestStep,
        onStepTapped: _onStepTapped,
        child:
            BlocSelector<
              AddBranchDraftCubit,
              AddBranchDraft,
              List<ServiceEntity>
            >(
              selector: (state) => state.selectedServices,
              builder: (context, services) {
                return AddBranchServicesStep(
                  selectedServices: services,
                  onAddServices: _openSelectServices,
                  onRemoveService: (service) {
                    context.read<AddBranchDraftCubit>().removeService(service);
                  },
                );
              },
            ),
      ),
      4 => AddBranchWizardStepShell(
        currentStep: _currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: _furthestStep,
        onStepTapped: _onStepTapped,
        child:
            BlocSelector<
              AddBranchDraftCubit,
              AddBranchDraft,
              List<WorkerEntity>
            >(
              selector: (state) => state.selectedWorkers,
              builder: (context, workers) {
                return AddBranchWorkersStep(
                  selectedWorkers: workers,
                  onAddWorkers: _openSelectWorkers,
                  onRemoveWorker: (worker) {
                    context.read<AddBranchDraftCubit>().removeWorker(worker);
                  },
                );
              },
            ),
      ),
      5 => AddBranchReviewStep(
        currentStep: _currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: _furthestStep,
        onStepTapped: _onStepTapped,
      ),
      _ => AddBranchWizardStepShell(
        currentStep: _currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: _furthestStep,
        onStepTapped: _onStepTapped,
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
}
