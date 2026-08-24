import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_schedule_mode.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/utils/branch_maps_launcher.dart';
import 'package:branches/src/presentation/utils/branch_summary_section_matcher.dart';
import 'package:branches/src/presentation/widgets/branch_info_edit_sheet.dart';
import 'package:branches/src/presentation/widgets/branch_summary_view.dart';
import 'package:branches/src/presentation/widgets/contact_edit_sheet.dart';
import 'package:branches/src/presentation/widgets/working_hours_edit_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add branch — pre-submit review summary of the draft.
///
/// Figma `review` (`365:14892`). Renders the draft through the shared
/// [BranchSummaryView] so it stays visually identical to branch details.
///
/// Every section is directly editable from here — each pencil opens the same
/// section editor used by Branch Details, but routes its result into
/// [AddBranchDraftCubit] (the local creation draft) instead of a backend
/// PATCH. Coverage, Services and Team reuse the wizard's own step handlers
/// (passed in) so location-permission checks and picker sheets stay a single
/// source of truth.
///
/// When a submit fails backend validation, the failing section (matched by
/// [matchFailureToSection]) is scrolled into view and highlighted so the user
/// can fix it without restarting the wizard.
class BranchReviewBody extends StatefulWidget {
  const BranchReviewBody({
    required this.onEditCoverage,
    required this.onEditServices,
    required this.onEditTeam,
    super.key,
  });

  final VoidCallback onEditCoverage;
  final VoidCallback onEditServices;
  final VoidCallback onEditTeam;

  @override
  State<BranchReviewBody> createState() => _BranchReviewBodyState();
}

class _BranchReviewBodyState extends State<BranchReviewBody> {
  final Map<BranchSummarySection, GlobalKey> _sectionKeys = {
    for (final section in BranchSummarySection.values) section: GlobalKey(),
  };

  BranchSummarySection? _highlightedSection;

  void _onSubmitFailure(BuildContext context, AddBranchState state) {
    final failure = state.failure;
    if (failure == null) return;
    final section = matchFailureToSection(failure);
    if (section == null) return;

    setState(() => _highlightedSection = section);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionContext = _sectionKeys[section]?.currentContext;
      if (sectionContext == null) return;
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 300),
        alignment: 0.1,
      );
    });
  }

  void _clearHighlight() {
    if (_highlightedSection != null) setState(() => _highlightedSection = null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddBranchBloc, AddBranchState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure && current.failure != null,
      listener: _onSubmitFailure,
      child: BlocBuilder<AddBranchDraftCubit, AddBranchDraft>(
        builder: (context, draft) {
          final companySchedule = context
              .watch<AddBranchBloc>()
              .state
              .companySchedule;
          final schedule = draft.scheduleMode == BranchScheduleMode.company
              ? companySchedule
              : draft.customSchedule;

          final position = draft.pickedPosition;

          return BranchSummaryView(
            data: BranchSummaryData(
              // The card title is the branch's own name, matching
              // BranchDetailsPage's `title: branch.branchName` — this is a
              // pre-submit preview of that same branch, not the umbrella
              // company/organization.
              title: draft.branchName,
              caption: branchTypeLabel(draft.branchType),
              badgeLabel: 'branches.status_active'.tr(),
              badgeType: AppStatusBadgeType.success,
              branchTypeLabel: branchTypeLabel(draft.branchType),
              position: position,
              address: draft.branchAddress,
              cityName: draft.selectedCity?.name,
              phone: draft.phone,
              managerName: draft.selectedManager?.fullName,
              isCustomSchedule: draft.scheduleMode == BranchScheduleMode.custom,
              schedule: schedule,
              areaNames: [for (final area in draft.servingAreas) area.name],
              serviceNames: [
                for (final service in draft.selectedServices) service.name,
              ],
              workerInitials: [
                for (final worker in draft.selectedWorkers) worker.initials,
              ],
            ),
            onOpenMaps: position == null
                ? null
                : () =>
                      _openMaps(context, position.latitude, position.longitude),
            onEditBranchInfo: () {
              _clearHighlight();
              _openBranchInfoEdit(context);
            },
            onEditContact: () {
              _clearHighlight();
              _openContactEdit(context);
            },
            onEditWorkingHours: () {
              _clearHighlight();
              _openWorkingHoursEdit(context, companySchedule);
            },
            onEditCoverage: () {
              _clearHighlight();
              widget.onEditCoverage();
            },
            onEditServices: () {
              _clearHighlight();
              widget.onEditServices();
            },
            onEditTeam: () {
              _clearHighlight();
              widget.onEditTeam();
            },
            sectionKeys: _sectionKeys,
            highlightedSection: _highlightedSection,
          );
        },
      ),
    );
  }

  Future<void> _openBranchInfoEdit(BuildContext context) async {
    final draft = context.read<AddBranchDraftCubit>().state;
    final result = await showBranchInfoEditSheet(
      context: context,
      initialName: draft.branchName,
      initialType: draft.branchType,
      initialCity: draft.selectedCity,
    );
    if (result == null || !context.mounted) return;

    final draftCubit = context.read<AddBranchDraftCubit>()
      ..updateBasicInfo(branchName: result.branchName)
      ..updateBranchType(result.branchType);
    if (result.city != null) draftCubit.updateCity(result.city!);
  }

  Future<void> _openContactEdit(BuildContext context) async {
    final draft = context.read<AddBranchDraftCubit>().state;
    final result = await showContactEditSheet(
      context: context,
      initialPhone: draft.phone,
      initialManager: draft.selectedManager,
    );
    if (result == null || !context.mounted) return;

    context.read<AddBranchDraftCubit>()
      ..updateBasicInfo(phone: result.branchPhone)
      ..updateManager(result.manager);
  }

  Future<void> _openWorkingHoursEdit(
    BuildContext context,
    List<BranchAvailabilityEntity> companySchedule,
  ) async {
    if (companySchedule.isEmpty) {
      showAppSnackbar(
        context: context,
        title: 'branches.details.status_update_error'.tr(),
      );
      return;
    }

    final draft = context.read<AddBranchDraftCubit>().state;
    final initialMode = draft.scheduleMode == BranchScheduleMode.custom
        ? BranchAvailabilityMode.custom
        : BranchAvailabilityMode.coreHours;

    final result = await showWorkingHoursEditSheet(
      context: context,
      initialMode: initialMode,
      initialCustomSchedule: draft.customSchedule,
      companySchedule: companySchedule,
    );
    if (result == null || !context.mounted) return;

    final mode = result.availabilityMode == BranchAvailabilityMode.custom
        ? BranchScheduleMode.custom
        : BranchScheduleMode.company;
    final draftCubit = context.read<AddBranchDraftCubit>()
      ..updateScheduleMode(mode);
    if (mode == BranchScheduleMode.custom) {
      draftCubit.updateCustomSchedule(result.availability);
    }
  }

  Future<void> _openMaps(BuildContext context, double lat, double lng) async {
    final opened = await BranchMapsLauncher.openCoordinates(lat, lng);
    if (!context.mounted || opened) return;
    showAppSnackbar(
      context: context,
      title: 'branches.details.maps_unavailable'.tr(),
    );
  }
}
