import 'package:app_logger/app_logger.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_location_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_wizard_cubit.dart';
import 'package:branches/src/presentation/models/coverage_area_args.dart';
import 'package:branches/src/presentation/models/coverage_area_result.dart';
import 'package:branches/src/presentation/utils/add_branch_error_snackbar.dart';
import 'package:branches/src/presentation/utils/add_branch_params_mapper.dart';
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
import 'package:shared_ui/shared_ui.dart';
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
  const AddBranchPage({super.key});

  @override
  State<AddBranchPage> createState() => _AddBranchPageState();
}

class _AddBranchPageState extends State<AddBranchPage>
    with WidgetsBindingObserver {
  final _stepOneFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Request location access from the very start of the flow (Step 1
    // already needs it for the address field) rather than deferring the
    // native prompt until Step 2 — see SAN-603.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AddBranchLocationCubit>().ensureAccess();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Source of truth is always a fresh OS read on resume — never the
    // outcome of the original request (fixes SAN-602: granting permission
    // from Settings and returning must clear the blocking state).
    if (state == AppLifecycleState.resumed) {
      context.read<AddBranchLocationCubit>().refresh();
    }
  }

  // ── Navigation ──

  void _handleBack() => context.read<AddBranchWizardCubit>().goBack();

  void _onNextPressed() {
    final wizard = context.read<AddBranchWizardCubit>();
    final draft = context.read<AddBranchDraftCubit>().state;

    switch (wizard.state.currentStep) {
      case 1:
        // Phone validity (UaePhoneValidator) is enforced by AppPhoneField's
        // own validator, part of this form — formValid already covers it.
        final formValid = _stepOneFormKey.currentState?.validate() ?? false;
        if (!formValid || !draft.isStepOneComplete) {
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

    final params = AddBranchParamsMapper.toCreateParams(
      draft,
      companySchedule: companySchedule,
    );
    bloc.add(AddBranchSubmitEvent(params: params));
  }

  // ── Flow pickers ──

  Future<void> _pickLocation() async {
    appLogger.d('[AddBranchPage] Add Location tapped');
    final draft = context.read<AddBranchDraftCubit>().state;
    final result = await showLocationPickerSheet(
      context,
      labels: LocationPickerLabels(
        title: 'branches.location_picker.title'.tr(),
        subtitle: 'branches.location_picker.subtitle'.tr(),
        searchHint: 'branches.location_picker.search_hint'.tr(),
        confirm: 'common.confirm'.tr(),
        specifiedLocation: 'branches.location_picker.specified_location'.tr(),
        addressHint: 'branches.location_picker.address_hint'.tr(),
        permissionDenied: 'branches.location_picker.permission_denied'.tr(),
        permissionPermanentlyDenied:
            'branches.location_picker'
                    '.permission_permanently_denied'
                .tr(),
        serviceDisabled: 'branches.location_picker.service_disabled'.tr(),
        genericError: 'branches.location_picker.generic_error'.tr(),
        openSettings: 'branches.location_picker.open_settings'.tr(),
        searchEmpty: 'branches.location_picker.no_results'.tr(),
        searchRetry: 'common.retry'.tr(),
        outsideCountry: 'branches.location_picker.outside_uae'.tr(),
        placeIdRequiredHint: 'branches.add_branch.location_select_from_search'
            .tr(),
      ),
      existingLocation: draft.pickedPosition,
      initialAddress: draft.branchAddress,
      requirePlaceId: true,
    );
    if (!mounted || result == null) return;

    context.read<AddBranchDraftCubit>().updateLocation(
      address: result.address,
      position: result.position,
      placeId: result.placeId,
    );
  }

  Future<void> _openCoverageArea() async {
    // Figma `location-permission-denied` (`1517:9804`). Re-checks through
    // the single location coordinator rather than the permission plugin
    // directly — the wizard's `coverageAccessDenied` is kept in sync with
    // this cubit by a listener in `build`, so a denial here just means the
    // blocking body is already (or about to be) shown.
    final locationCubit = context.read<AddBranchLocationCubit>();
    await locationCubit.refresh();
    if (!mounted || !locationCubit.state.isGranted) return;

    final draft = context.read<AddBranchDraftCubit>().state;
    final result = await context.push<CoverageAreaResult>(
      BranchRoutes.coverage,
      extra: CoverageAreaArgs(
        position: draft.pickedPosition,
        address: draft.branchAddress,
        radiusKm: draft.coverageRadiusKm,
        servingAreas: draft.servingAreas,
        mode: CoverageMode.create,
      ),
    );
    if (!mounted || result == null) return;

    final draftCubit = context.read<AddBranchDraftCubit>()
      ..updateCoverage(
        address: result.address,
        position: result.position,
        radiusKm: result.radiusKm,
        servingAreas: result.servingAreas,
        placeId: result.placeId,
      );

    // Coverage confirmed → auto-advance to services step.
    final wizard = context.read<AddBranchWizardCubit>();
    if (wizard.state.currentStep == 2 && draftCubit.state.isStepTwoComplete) {
      wizard.advanceTo(3);
    }
  }

  Future<void> _openSelectServices() async {
    final draft = context.read<AddBranchDraftCubit>().state;
    final result = await showSelectServiceActionSheet(
      context: context,
      loadItems: _loadCatalogServiceSelections,
      initialSelectedIds: draft.selectedServices.map((s) => s.id).toSet(),
    );
    if (!mounted || result == null) return;
    context.read<AddBranchDraftCubit>().updateServices(result.selectedServices);
  }

  /// Builds the `loadItems` closure `showSelectServiceActionSheet` needs
  /// from [BrowseCatalogUseCase] (`GET /services`, mapped down to the
  /// lightweight [CatalogServiceSelection] shape the sheet expects) — this
  /// page resolves and owns the use case itself, as its own composition
  /// root, rather than the sheet (a shared `services` package widget)
  /// doing so.
  Future<List<CatalogServiceSelection>> _loadCatalogServiceSelections() async {
    final result = await sl<BrowseCatalogUseCase>()(
      const BrowseCatalogParams(limit: 100),
    ).run();
    return result.fold(
      (f) => throw f,
      (paged) => [
        for (final service in paged.items)
          CatalogServiceSelection(
            id: service.id,
            name: service.name,
            categoryName: service.category.name,
          ),
      ],
    );
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
      context.read<AddBranchLocationCubit>().openSettings();

  Future<void> _requestLocationAgain() =>
      context.read<AddBranchLocationCubit>().requestAgain();

  // ── Bloc side effects ──

  /// Surfaces setup (company-schedule fetch) errors. Kept separate from the
  /// submit mutation (below), which `MutationListener` owns.
  void _onSetupStatusChanged(BuildContext context, AddBranchState state) {
    if (state.hasSetupError && state.setupFailure != null) {
      showAddBranchErrorSnackbar(
        context: context,
        failure: state.setupFailure!,
      );
    }
  }

  void _showSuccessPopover() {
    // Figma `1546:8473`.
    const prefix = 'branches.add_branch';
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
      title: 'common.discard_title'.tr(),
      description: 'branches.add_branch.discard_description'.tr(),
      imageLayout: AppDialogImageLayout.iconSmall,
      featureIconColor: AppFeatureIconColor.warning,
      primaryLabel: 'common.discard'.tr(),
      primaryDestructive: true,
      secondaryLabel: 'common.keep_editing'.tr(),
      onPrimary: () => Navigator.of(context, rootNavigator: true).pop(true),
      onSecondary: () => Navigator.of(context, rootNavigator: true).pop(false),
    );

    if ((discard ?? false) && mounted) context.pop();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return MutationListener<AddBranchBloc, AddBranchState>(
      status: (state) => state.status,
      title: (context) => 'branches.add_branch.submitting_title'.tr(),
      description: (context) =>
          'branches.add_branch.submitting_description'.tr(),
      onSuccess: (context, state) => _showSuccessPopover(),
      onFailure: (context, state) {
        if (state.failure != null) {
          showAddBranchErrorSnackbar(context: context, failure: state.failure!);
        }
      },
      child: BlocListener<AddBranchBloc, AddBranchState>(
        listenWhen: (previous, current) =>
            previous.setupStatus != current.setupStatus,
        listener: _onSetupStatusChanged,
        child: BlocListener<AddBranchLocationCubit, AddBranchLocationState>(
          listenWhen: (previous, current) => current.hasChecked,
          listener: (context, state) {
            context.read<AddBranchWizardCubit>().setCoverageAccessDenied(
              denied: !state.isGranted,
            );
          },
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
                    if (wizard.currentStep == _reviewStep) {
                      return _buildReviewScreen();
                    }
                    return _buildWizardScreen(wizard);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shared nav bar: X/Close stays on the leading side; a back chevron
  /// (previous-step, never discard/exit) appears opposite it once past
  /// step 1. Hidden on step 1 per the ticket — X remains the only exit.
  Widget _buildNavBar(int currentStep) {
    final showBack = currentStep > 1;
    final spec = context.appNavBarTheme.standard;
    return AppNavBar(
      title: '',
      leading: AppCloseIcon(onTap: _handleClose),
      trailingAction: showBack
          ? AppNavBarTrailingAction.icon
          : AppNavBarTrailingAction.none,
      trailing: showBack
          ? Semantics(
              label: 'common.back'.tr(),
              child: Icon(
                Icons.chevron_left,
                size: spec.iconSize,
                color: spec.titleStyle.color,
              ),
            )
          : null,
      onTrailingTap: showBack ? _handleBack : null,
    );
  }

  Widget _buildWizardScreen(AddBranchWizardState wizard) {
    final location = context.watch<AddBranchLocationCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNavBar(wizard.currentStep),
        Expanded(child: _buildCurrentStep(wizard, location)),
        AddBranchWizardFooter(
          currentStep: wizard.currentStep,
          onNext: _onNextPressed,
          onSubmit: _submit,
          onAddCoverage: _openCoverageArea,
          onAddServices: _openSelectServices,
          onAddWorkers: _openSelectWorkers,
          coverageAccessDenied: wizard.coverageAccessDenied,
          locationPermanentlyBlocked: location.isBlocked,
          onOpenLocationSettings: _openLocationSettings,
          onRequestLocationAgain: _requestLocationAgain,
        ),
      ],
    );
  }

  Widget _buildReviewScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNavBar(_reviewStep),
        Expanded(
          child: BranchReviewBody(
            onEditCoverage: _openCoverageArea,
            onEditServices: _openSelectServices,
            onEditTeam: _openSelectWorkers,
          ),
        ),
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
                label: 'branches.review.submit'.tr(),
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(
    AddBranchWizardState wizard,
    AddBranchLocationState location,
  ) {
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
        child: AddBranchLocationPermissionBody(
          status: location.status ?? LocationPermissionStatus.denied,
        ),
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
              List<CatalogServiceSelection>
            >(
              selector: (state) => state.selectedServices,
              builder: (context, services) {
                return AddBranchServicesStep(
                  selectedServices: services,
                  onAddServices: _openSelectServices,
                  onRemoveService: context
                      .read<AddBranchDraftCubit>()
                      .removeService,
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
