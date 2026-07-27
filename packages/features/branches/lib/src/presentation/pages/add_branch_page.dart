import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_wizard_cubit.dart';
import 'package:branches/src/presentation/models/branch_form_mode.dart';
import 'package:branches/src/presentation/models/coverage_area_args.dart';
import 'package:branches/src/presentation/models/coverage_area_result.dart';
import 'package:branches/src/presentation/utils/add_branch_error_snackbar.dart';
import 'package:branches/src/presentation/utils/add_branch_params_mapper.dart';
import 'package:branches/src/presentation/utils/branch_draft_seeder.dart';
import 'package:branches/src/presentation/widgets/add_branch_coverage_step.dart';
import 'package:branches/src/presentation/widgets/add_branch_location_permission_body.dart';
import 'package:branches/src/presentation/widgets/add_branch_services_step.dart';
import 'package:branches/src/presentation/widgets/add_branch_step_one.dart';
import 'package:branches/src/presentation/widgets/add_branch_wizard_footer.dart';
import 'package:branches/src/presentation/widgets/add_branch_wizard_step_shell.dart';
import 'package:branches/src/presentation/widgets/add_branch_workers_step.dart';
import 'package:branches/src/presentation/widgets/branch_review_body.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

/// Coverage fields selected from the draft to render the step 2 preview.
typedef _CoveragePreview = ({
  LatLng? position,
  double? radiusKm,
  String? address,
  List<String> areaNames,
});

const _totalSteps = 4;

/// Pre-submit review screen (`365:14892`), shown after the 4 wizard steps.
const _reviewStep = 5;

class AddBranchPage extends StatefulWidget {
  const AddBranchPage({
    this.mode = BranchFormMode.create,
    this.branchId,
    this.initialBranch,
    super.key,
  });

  final BranchFormMode mode;
  final String? branchId;
  final BranchEntity? initialBranch;

  @override
  State<AddBranchPage> createState() => _AddBranchPageState();
}

class _AddBranchPageState extends State<AddBranchPage> {
  final _stepOneFormKey = GlobalKey<FormState>();

  bool get _isEdit => widget.mode.isEdit;

  @override
  void initState() {
    super.initState();
    if (_isEdit && widget.initialBranch == null) {
      // Edit-by-id: seed the draft only after the branch is fetched.
      context.read<AddBranchWizardCubit>().markSeedingRequired();
      context.read<AddBranchBloc>().add(
        AddBranchLoadForEditEvent(branchId: widget.branchId!),
      );
    }
  }

  // ── Navigation ──

  void _onNextPressed() {
    final wizard = context.read<AddBranchWizardCubit>();
    final draft = context.read<AddBranchDraftCubit>().state;

    switch (wizard.state.currentStep) {
      case 1:
        final formValid = _stepOneFormKey.currentState?.validate() ?? false;
        final phoneValid = draft.phone.trim().isNotEmpty &&
            UaePhoneValidator.isValid(draft.phone);
        if (!formValid || !draft.isStepOneComplete || !phoneValid) {
          // Surface the Figma inline field errors (`1513:7801` error frame).
          wizard.showStepOneErrors();
          return;
        }
        wizard.advanceTo(2);
      case 2:
        if (draft.isStepTwoComplete) wizard.advanceTo(3);
      case 3:
        if (draft.isStepThreeComplete) wizard.advanceTo(4);
      case 4:
        if (draft.isStepFourComplete) wizard.advanceTo(_reviewStep);
    }
  }

  // ── Submission ──

  void _submit() {
    final draft = context.read<AddBranchDraftCubit>().state;
    final bloc = context.read<AddBranchBloc>();
    final companySchedule = bloc.state.companySchedule;

    if (_isEdit) {
      final params = AddBranchParamsMapper.toUpdateParams(
        draft,
        id: widget.branchId ?? widget.initialBranch!.id,
        companySchedule: companySchedule,
      );
      bloc.add(UpdateBranchSubmitEvent(params: params));
      return;
    }

    final params = AddBranchParamsMapper.toCreateParams(
      draft,
      companySchedule: companySchedule,
    );
    bloc.add(AddBranchSubmitEvent(params: params));
  }

  // ── Flow pickers ──

  Future<void> _pickLocation() async {
    final draft = context.read<AddBranchDraftCubit>().state;
    final result = await showLocationPickerSheet(
      context,
      labels: LocationPickerLabels(
        title: 'branches.location_picker.title'.tr(),
        subtitle: 'branches.location_picker.subtitle'.tr(),
        searchHint: 'branches.location_picker.search_hint'.tr(),
        confirm: 'branches.location_picker.confirm'.tr(),
        specifiedLocation: 'branches.location_picker.specified_location'.tr(),
        addressHint: 'branches.location_picker.address_hint'.tr(),
        permissionDenied: 'branches.location_picker.permission_denied'.tr(),
        permissionPermanentlyDenied: 'branches.location_picker'
                '.permission_permanently_denied'
            .tr(),
        serviceDisabled: 'branches.location_picker.service_disabled'.tr(),
        genericError: 'branches.location_picker.generic_error'.tr(),
        openSettings: 'branches.location_picker.open_settings'.tr(),
        searchEmpty: 'branches.location_picker.no_results'.tr(),
        searchRetry: 'empty_states.retry'.tr(),
        outsideCountry: 'branches.location_picker.outside_uae'.tr(),
      ),
      existingLocation: draft.pickedPosition,
      initialAddress: draft.branchAddress,
    );
    if (!mounted || result == null) return;

    context.read<AddBranchDraftCubit>().updateLocation(
      address: result.address,
      position: result.position,
    );
  }

  Future<void> _openCoverageArea() async {
    // Figma `location-permission-denied` (`1517:9804`).
    final status = await sl<LocationService>().checkPermission();
    if (!mounted) return;
    final wizard = context.read<AddBranchWizardCubit>();
    final denied = status == LocationPermissionStatus.permanentlyDenied ||
        status == LocationPermissionStatus.serviceDisabled;
    wizard.setCoverageAccessDenied(denied: denied);
    if (denied) return;

    final draft = context.read<AddBranchDraftCubit>().state;
    final result = await context.push<CoverageAreaResult>(
      BranchRoutes.coverage,
      extra: CoverageAreaArgs(
        position: draft.pickedPosition,
        address: draft.branchAddress,
        radiusKm: draft.coverageRadiusKm,
        servingAreas: draft.servingAreas,
        mode: _isEdit ? CoverageMode.edit : CoverageMode.create,
      ),
    );
    if (!mounted || result == null) return;

    final draftCubit = context.read<AddBranchDraftCubit>()
      ..updateCoverage(
        address: result.address,
        position: result.position,
        radiusKm: result.radiusKm,
        servingAreas: result.servingAreas,
      );

    // Create: coverage confirmed → auto-advance to services step.
    if (!_isEdit &&
        wizard.state.currentStep == 2 &&
        draftCubit.state.isStepTwoComplete) {
      wizard.advanceTo(3);
    }
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

  Future<void> _openLocationSettings() =>
      sl<LocationService>().openAppSettings();

  // ── Bloc side effects ──

  void _onBlocStateChanged(BuildContext context, AddBranchState state) {
    final wizard = context.read<AddBranchWizardCubit>();

    // Edit-by-id: seed the draft once the branch has been fetched.
    if (_isEdit && !wizard.state.isSeeded) {
      if (state.loadStatus == RequestStatus.success &&
          state.loadedBranch != null) {
        context.read<AddBranchDraftCubit>().seed(
          BranchDraftSeeder.fromBranch(state.loadedBranch!),
        );
        wizard.markSeeded();
      } else if (state.hasLoadError && state.loadFailure != null) {
        showAddBranchErrorSnackbar(
          context: context,
          failure: state.loadFailure!,
        );
      }
    }

    if (state.isLoading) {
      _showSubmittingDialog();
      return;
    }
    _dismissSubmittingDialog();

    if (state.isSuccess) {
      _showSuccessPopover();
    } else if (state.hasError && state.failure != null) {
      showAddBranchErrorSnackbar(context: context, failure: state.failure!);
    } else if (state.hasSetupError && state.setupFailure != null) {
      showAddBranchErrorSnackbar(context: context, failure: state.setupFailure!);
    }
  }

  /// Figma loading-state dialog (`1546:8536`) while the submit is in flight.
  void _showSubmittingDialog() {
    final wizard = context.read<AddBranchWizardCubit>();
    if (wizard.state.submittingDialogVisible) return;
    wizard.markSubmittingDialogShown();

    showAppProgressDialog(
      context: context,
      title: 'branches.add_branch.submitting_title'.tr(),
      description: 'branches.add_branch.submitting_description'.tr(),
    ).whenComplete(
      () {
        if (mounted) {
          context
              .read<AddBranchWizardCubit>()
              .markSubmittingDialogDismissed();
        }
      },
    );
  }

  void _dismissSubmittingDialog() {
    final wizard = context.read<AddBranchWizardCubit>();
    if (!wizard.state.submittingDialogVisible) return;
    wizard.markSubmittingDialogDismissed();
    dismissAppProgressDialog(context);
  }

  void _showSuccessPopover() {
    // Figma `1546:8473`. Create vs edit only swaps the localization prefix.
    final prefix = _isEdit ? 'branches.edit_branch' : 'branches.add_branch';
    final titleStyle = AppSuccessPopover.titleStyleOf(context);

    showAppSuccessPopover<void>(
      context: context,
      title: '',
      titleWidget: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$prefix.success_dialog_title_highlight'.tr(),
              style: titleStyle,
            ),
            TextSpan(
              text: '$prefix.success_dialog_title_body'.tr(),
              style: titleStyle,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      description: '$prefix.success_dialog_description'.tr(),
      primaryLabel: '$prefix.success_dialog_okay'.tr(),
    ).then((_) {
      // Signal the branch list / details to refresh — EH-S3-02 convention.
      if (mounted) context.pop(true);
    });
  }

  // ── Discard guard ──

  Future<void> _handleClose() async {
    final hasChanges = context.read<AddBranchDraftCubit>().hasChanges;
    if (!hasChanges) {
      context.pop();
      return;
    }

    final discard = await showAppPopover<bool>(
      context: context,
      title: 'branches.add_branch.discard_title'.tr(),
      description: 'branches.add_branch.discard_description'.tr(),
      imageLayout: AppDialogImageLayout.iconSmall,
      featureIconColor: AppFeatureIconColor.warning,
      primaryLabel: 'branches.add_branch.discard_confirm'.tr(),
      primaryDestructive: true,
      secondaryLabel: 'branches.add_branch.discard_cancel'.tr(),
      onPrimary: () => Navigator.of(context, rootNavigator: true).pop(true),
      onSecondary: () => Navigator.of(context, rootNavigator: true).pop(false),
    );

    if ((discard ?? false) && mounted) context.pop();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddBranchBloc, AddBranchState>(
      listener: _onBlocStateChanged,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleClose();
        },
        child: Scaffold(
          backgroundColor: context.appColors.surface,
          body: SafeArea(
            child: BlocBuilder<AddBranchWizardCubit, AddBranchWizardState>(
              builder: (context, wizard) {
                if (_isEdit && !wizard.isSeeded) return _buildSeedingScreen();
                if (wizard.currentStep == _reviewStep) {
                  return _buildReviewScreen();
                }
                return _buildWizardScreen(wizard);
              },
            ),
          ),
        ),
      ),
    );
  }

  String get _navTitle => _isEdit ? 'branches.edit_branch.title'.tr() : '';

  Widget _buildSeedingScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNavBar(
          title: _navTitle,
          leading: AppCloseIcon(onTap: () => context.pop()),
        ),
        Expanded(
          child: BlocSelector<AddBranchBloc, AddBranchState, bool>(
            selector: (state) => state.hasLoadError,
            builder: (context, hasError) {
              if (hasError) {
                return Center(
                  child: AppButton(
                    label: 'empty_states.retry'.tr(),
                    onPressed: () => context.read<AddBranchBloc>().add(
                      AddBranchLoadForEditEvent(branchId: widget.branchId!),
                    ),
                  ),
                );
              }
              return const Center(child: AppLoadingIndicator());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWizardScreen(AddBranchWizardState wizard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNavBar(
          title: _navTitle,
          leading: AppCloseIcon(onTap: _handleClose),
        ),
        Expanded(child: _buildCurrentStep(wizard)),
        AddBranchWizardFooter(
          currentStep: wizard.currentStep,
          isEdit: _isEdit,
          onNext: _onNextPressed,
          onSubmit: _submit,
          onAddCoverage: _openCoverageArea,
          onAddServices: _openSelectServices,
          onAddWorkers: _openSelectWorkers,
          coverageAccessDenied: wizard.coverageAccessDenied,
          onOpenLocationSettings: _openLocationSettings,
        ),
      ],
    );
  }

  Widget _buildReviewScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNavBar(
          title: _navTitle,
          leading: AppCloseIcon(onTap: _handleClose),
        ),
        const Expanded(child: BranchReviewBody()),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.sm,
          ),
          child: BlocSelector<AddBranchBloc, AddBranchState, bool>(
            selector: (state) => state.isLoading,
            builder: (context, isLoading) {
              return AppButton(
                label: _isEdit
                    ? 'branches.edit_branch.save_button'.tr()
                    : 'branches.review.submit'.tr(),
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(AddBranchWizardState wizard) {
    final wizardCubit = context.read<AddBranchWizardCubit>();

    return switch (wizard.currentStep) {
      1 => AddBranchStepOne(
        formKey: _stepOneFormKey,
        onPickLocation: _pickLocation,
        currentStep: wizard.currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: wizard.furthestStep,
        onStepTapped: wizardCubit.tapStep,
        showValidationErrors: wizard.showStepOneErrors,
      ),
      2 when wizard.coverageAccessDenied => AddBranchWizardStepShell(
        currentStep: wizard.currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: wizard.furthestStep,
        onStepTapped: wizardCubit.tapStep,
        child: const AddBranchLocationPermissionBody(),
      ),
      2 => AddBranchWizardStepShell(
        currentStep: wizard.currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: wizard.furthestStep,
        onStepTapped: wizardCubit.tapStep,
        child:
            BlocSelector<AddBranchDraftCubit, AddBranchDraft, _CoveragePreview>(
              selector: (state) => (
                position: state.pickedPosition,
                radiusKm: state.coverageRadiusKm,
                address: state.branchAddress,
                areaNames: state.servingAreas
                    .map((a) => a.name)
                    .where((n) => n.isNotEmpty)
                    .toList(),
              ),
              builder: (context, cov) {
                return AddBranchCoverageStep(
                  onEditCoverage: _openCoverageArea,
                  position: cov.position,
                  radiusKm: cov.radiusKm,
                  address: cov.address,
                  areaNames: cov.areaNames,
                );
              },
            ),
      ),
      3 => AddBranchWizardStepShell(
        currentStep: wizard.currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: wizard.furthestStep,
        onStepTapped: wizardCubit.tapStep,
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
                  onRemoveService:
                      context.read<AddBranchDraftCubit>().removeService,
                );
              },
            ),
      ),
      4 => AddBranchWizardStepShell(
        currentStep: wizard.currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: wizard.furthestStep,
        onStepTapped: wizardCubit.tapStep,
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
      _ => AddBranchWizardStepShell(
        currentStep: wizard.currentStep,
        totalSteps: _totalSteps,
        furthestCompletedStep: wizard.furthestStep,
        onStepTapped: wizardCubit.tapStep,
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
