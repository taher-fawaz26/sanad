import 'package:authorization/authorization.dart';
import 'package:branches/src/data/models/person_initials.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/usecases/get_company_schedule_usecase.dart';
import 'package:branches/src/presentation/bloc/branch_details/branch_details_bloc.dart';
import 'package:branches/src/presentation/models/coverage_area_args.dart';
import 'package:branches/src/presentation/models/coverage_area_result.dart';
import 'package:branches/src/presentation/utils/add_branch_params_mapper.dart';
import 'package:branches/src/presentation/utils/branch_maps_launcher.dart';
import 'package:branches/src/presentation/widgets/branch_info_edit_sheet.dart';
import 'package:branches/src/presentation/widgets/branch_summary_view.dart';
import 'package:branches/src/presentation/widgets/contact_edit_sheet.dart';
import 'package:branches/src/presentation/widgets/working_hours_edit_sheet.dart';
import 'package:branches/src/routes/branch_permissions.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:maps/maps.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:workers/workers.dart';

/// Realistic mock used only to skeletonize the real details layout via
/// [AppSkeletonizer]. `lat`/`lng` are left null so [BranchSummaryView] skips
/// the map preview instead of rendering one against a fake position.
final _skeletonBranch = BranchEntity(
  id: 'skeleton',
  branchName: BoneMock.words(2),
  branchAddress: BoneMock.address,
  city: BoneMock.city,
  branchPhone: BoneMock.phone,
  isAvailable: true,
  availabilityMode: BranchAvailabilityMode.coreHours,
);

/// Figma Branch Details screen (`365:14892`).
///
/// Read-only by default; each editable section (Branch Info, Contact,
/// Working Hours, Coverage, Team) has its own pencil that opens a focused
/// bottom-sheet/section editor. Services stays read-only (see Phase 0 audit
/// note in the migration plan — the backend currently ignores `serviceIds`).
class BranchDetailsPage extends StatelessWidget {
  const BranchDetailsPage({
    required this.branchId,
    required this.isOwner,
    super.key,
  });

  final String branchId;

  /// Whether the signed-in account is a provider owner (individual or
  /// organization) — gates the Delete action-sheet item, which is
  /// persona-controlled (no `provider:branch:delete` permission exists —
  /// RBAC backend gap G2).
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BranchDetailsBloc, BranchDetailsState>(
      listenWhen: (prev, curr) =>
          (prev.statusUpdateFailure != curr.statusUpdateFailure &&
              curr.statusUpdateFailure != null) ||
          (prev.sectionSaveFailure != curr.sectionSaveFailure &&
              curr.sectionSaveFailure != null),
      listener: (context, state) {
        final failure = state.sectionSaveFailure ?? state.statusUpdateFailure;
        showAppErrorSnackbar(
          context: context,
          title: failure != null
              ? failure.localizedMessage()
              : 'branches.details.status_update_error'.tr(),
        );
      },
      builder: (context, state) {
        if (state.isLoading && state.branch == null) {
          // Skeletonize the *real* details layout with mock data instead of
          // a bespoke skeleton widget.
          return Scaffold(
            body: AppSkeletonizer(
              enabled: true,
              child: _BranchDetailsContent(
                branch: _skeletonBranch,
                isOwner: isOwner,
              ),
            ),
          );
        }

        if (state.hasError && state.branch == null) {
          return _BranchDetailsError(
            failure: state.failure,
            onRetry: () => context.read<BranchDetailsBloc>().add(
              const BranchDetailsRefreshEvent(),
            ),
            onClose: () => context.pop(),
          );
        }

        final branch = state.branch;
        if (branch == null) {
          return const SizedBox.shrink();
        }

        return _BranchDetailsContent(branch: branch, isOwner: isOwner);
      },
    );
  }
}

class _BranchDetailsError extends StatelessWidget {
  const _BranchDetailsError({
    required this.onRetry,
    required this.onClose,
    this.failure,
  });

  final Failure? failure;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            AppNavBar(
              title: '',
              leading: AppCloseIcon(onTap: onClose),
            ),
            Expanded(
              child: Center(child: _errorContent()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorContent() {
    final display = failureErrorDisplay(failure);
    return AppErrorState(
      style: display.isConnectivity
          ? AppErrorStateStyle.network
          : AppErrorStateStyle.generic,
      title: display.title,
      description: display.description,
      retryLabel: failureRetryLabel(),
      onRetry: display.isRetryable ? onRetry : null,
    );
  }
}

class _BranchDetailsContent extends StatelessWidget {
  const _BranchDetailsContent({required this.branch, required this.isOwner});

  final BranchEntity branch;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final managerCaption = branch.branchManagerName == null
        ? null
        : 'branches.details.manager_caption'.tr(
            namedArgs: {'name': branch.branchManagerName!},
          );
    final position = (branch.lat != null && branch.lng != null)
        ? LatLng(branch.lat!, branch.lng!)
        : null;
    final areaNames = (branch.servingAreaNames?.isNotEmpty ?? false)
        ? branch.servingAreaNames!
        : (branch.servingAreaPlaceIds ?? const <String>[]);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavBar(
              title: '',
              leading: AppCloseIcon(onTap: () => context.pop()),
              trailingAction: AppNavBarTrailingAction.icon,
              trailing: Icon(
                Icons.more_vert,
                size: 24,
                color: colors.textPrimary,
              ),
              onTrailingTap: () => _showMoreActions(context),
            ),
            Expanded(
              // All five sections gate on the same permission — there is
              // no per-section backend distinction — so one `Permission
              // Builder` covers them (RBAC Phase 7N: no more raw
              // `AuthorizationReader.can(...)` reads in leaf widgets).
              // A `null` callback renders the section pencil-free per
              // `BranchSummaryView`'s own contract.
              child: PermissionBuilder(
                requirement: const PermissionRequirement.single(
                  BranchPermissions.update,
                ),
                builder: (context, canUpdate) {
                  return BranchSummaryView(
                    data: BranchSummaryData(
                      title: branch.branchName,
                      caption: managerCaption ?? branch.displayAddress,
                      badgeLabel: branch.isAvailable
                          ? 'branches.status_active'.tr()
                          : 'branches.status_maintenance'.tr(),
                      badgeType: branch.isAvailable
                          ? AppStatusBadgeType.success
                          : AppStatusBadgeType.warning,
                      branchTypeLabel: branchTypeLabel(branch.branchType),
                      position: position,
                      address: branch.displayAddress,
                      cityName: branch.city,
                      phone: branch.branchPhone,
                      managerName: branch.branchManagerName,
                      isCustomSchedule:
                          branch.availabilityMode ==
                          BranchAvailabilityMode.custom,
                      schedule: branch.availability ?? const [],
                      areaNames: areaNames,
                      serviceNames: branch.serviceNames ?? const [],
                      workerInitials: [
                        for (final worker in branch.workers) worker.initials,
                      ],
                    ),
                    onOpenMaps: () => _openMaps(context),
                    onEditBranchInfo: canUpdate
                        ? () => _openBranchInfoEdit(context)
                        : null,
                    onEditContact: canUpdate
                        ? () => _openContactEdit(context)
                        : null,
                    onEditWorkingHours: canUpdate
                        ? () => _openWorkingHoursEdit(context)
                        : null,
                    onEditCoverage: canUpdate
                        ? () => _openCoverageEdit(context)
                        : null,
                    onEditTeam: canUpdate ? () => _openTeamEdit(context) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBranchInfoEdit(BuildContext context) async {
    final result = await showBranchInfoEditSheet(
      context: context,
      initialName: branch.branchName,
      initialType: branch.branchType,
      cityDisplayName: branch.city.isNotEmpty ? branch.city : null,
    );
    if (result == null || !context.mounted) return;

    final updated = branch.copyWith(
      branchName: result.branchName,
      branchType: result.branchType,
    );
    context.read<BranchDetailsBloc>().add(
      BranchSectionUpdated(AddBranchParamsMapper.fromBranch(updated)),
    );
  }

  Future<void> _openContactEdit(BuildContext context) async {
    final initialManager = branch.branchManagerId == null
        ? null
        : BranchManagerEntity(
            id: branch.branchManagerId!,
            fullName: branch.branchManagerName ?? '',
            initials: personInitials(branch.branchManagerName ?? ''),
          );

    final result = await showContactEditSheet(
      context: context,
      initialPhone: branch.branchPhone,
      initialManager: initialManager,
    );
    if (result == null || !context.mounted) return;

    final updated = branch.copyWith(
      branchPhone: result.branchPhone,
      branchManagerId: result.manager?.id,
      branchManagerName: result.manager?.fullName,
    );
    context.read<BranchDetailsBloc>().add(
      BranchSectionUpdated(AddBranchParamsMapper.fromBranch(updated)),
    );
  }

  Future<void> _openWorkingHoursEdit(BuildContext context) async {
    // Fetched up front so the sheet renders its full content from the very
    // first frame — swapping a loading state in after mount fights the
    // sheet's auto-sizing (`SheetSize.content`) while it settles.
    final scheduleResult = await sl<GetCompanyScheduleUseCase>()(
      const NoParams(),
    ).run();
    if (!context.mounted) return;

    final companySchedule = scheduleResult.fold((failure) => null, (s) => s);
    if (companySchedule == null) {
      showAppSnackbar(
        context: context,
        title: 'branches.details.status_update_error'.tr(),
      );
      return;
    }

    final result = await showWorkingHoursEditSheet(
      context: context,
      initialMode: branch.availabilityMode,
      initialCustomSchedule: branch.availability ?? const [],
      companySchedule: companySchedule,
    );
    if (result == null || !context.mounted) return;

    final updated = branch.copyWith(
      availabilityMode: result.availabilityMode,
      availability: result.availability,
    );
    context.read<BranchDetailsBloc>().add(
      BranchSectionUpdated(AddBranchParamsMapper.fromBranch(updated)),
    );
  }

  Future<void> _openCoverageEdit(BuildContext context) async {
    final status = await sl<LocationService>().checkPermission();
    if (!context.mounted) return;
    if (status == LocationPermissionStatus.permanentlyDenied ||
        status == LocationPermissionStatus.serviceDisabled) {
      showAppSnackbar(
        context: context,
        title: 'branches.add_branch.location_access_description'.tr(),
      );
      return;
    }

    final position = (branch.lat != null && branch.lng != null)
        ? LatLng(branch.lat!, branch.lng!)
        : null;

    final result = await context.push<CoverageAreaResult>(
      BranchRoutes.coverage,
      extra: CoverageAreaArgs(
        position: position,
        address: branch.branchAddress,
        radiusKm: branch.radiusKm,
        servingAreas: branch.servingAreas,
        mode: CoverageMode.edit,
      ),
    );
    if (result == null || !context.mounted) return;

    final updated = branch.copyWith(
      branchAddress: result.address,
      lat: result.position.latitude,
      lng: result.position.longitude,
      radiusKm: result.radiusKm,
      locationPlaceId: result.placeId ?? branch.locationPlaceId,
      servingAreas: result.servingAreas,
      servingAreaPlaceIds: result.servingAreaPlaceIds,
      servingAreaNames: [for (final area in result.servingAreas) area.name],
    );
    context.read<BranchDetailsBloc>().add(
      BranchSectionUpdated(AddBranchParamsMapper.fromBranch(updated)),
    );
  }

  Future<void> _openTeamEdit(BuildContext context) async {
    final result = await showSelectWorkerActionSheet(
      context: context,
      initialSelectedIds: branch.workers.map((w) => w.id).toSet(),
    );
    if (result == null || !context.mounted) return;

    if (result.selectedWorkers.isEmpty) {
      showAppSnackbar(
        context: context,
        title: 'branches.details.team_min_workers_error'.tr(),
      );
      return;
    }

    context.read<BranchDetailsBloc>().add(
      BranchSectionUpdated(
        AddBranchParamsMapper.fromBranch(
          branch,
          workerIds: result.selectedWorkers
              .map((w) => w.id)
              .toList(growable: false),
        ),
      ),
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final opened = await BranchMapsLauncher.openBranchLocation(branch);
    if (!context.mounted) return;
    if (!opened) {
      showAppSnackbar(
        context: context,
        title: 'branches.details.maps_unavailable'.tr(),
      );
    }
  }

  void _showMoreActions(BuildContext context) {
    final isActive = branch.isAvailable;
    final bloc = context.read<BranchDetailsBloc>();
    // Callback-time decision — no reactive rebuild needed once the sheet
    // opens. `context.can(...)` (RBAC Phase 7O) reads the DI-registered
    // reader without pulling `sl<AuthorizationReader>()` into a leaf
    // widget's callback surface.
    final canUpdate = context.can(BranchPermissions.update);
    SheetNavigator.push<void>(
      context,
      AppActionList(
        items: [
          if (canUpdate)
            AppActionSheetItem(
              label: isActive
                  ? 'branches.details.action_set_maintenance'.tr()
                  : 'branches.details.action_set_active'.tr(),
              leading: Icon(
                isActive
                    ? Icons.pause_circle_outline
                    : Icons.check_circle_outline,
              ),
              onTap: () {
                bloc.add(BranchStatusToggleEvent(isAvailable: !isActive));
              },
            ),
          // TODO(G2): no `provider:branch:delete` permission exists yet
          // (same gap as the row swipe action in `branch_list_item.dart`)
          // — persona-controlled via `isOwner`, not a proxy on
          // `branch:update`. Replace with a real permission check once
          // G2 ships.
          if (isOwner)
            AppActionSheetItem(
              label: 'branches.details.action_delete'.tr(),
              leading: const Icon(Icons.delete_outline),
              isDestructive: true,
              onTap: () {
                _showComingSoon(
                  context,
                  'branches.details.delete_coming_soon'.tr(),
                );
              },
            ),
        ],
      ),
      settings: const SheetRouteSettings(padChild: false),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    showAppSnackbar(context: context, title: message);
  }
}
