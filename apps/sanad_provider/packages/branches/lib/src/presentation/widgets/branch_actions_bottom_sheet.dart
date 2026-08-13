import 'package:app_assets/app_assets.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Figma `Views / Bottom Sheets` branch actions (`287:7642`).
Future<void> showBranchActionsBottomSheet({
  required BuildContext context,
  required BranchEntity branch,
}) {
  // The bottom sheet runs in a new route. Capture the bloc + page context
  // before opening so confirm popovers can be shown after the sheet closes.
  final bloc = context.read<BranchesBloc>();
  final pageContext = context;

  return SheetNavigator.push<void>(
    context,
    BlocProvider.value(
      value: bloc,
      child: _BranchActionsSheetBody(branch: branch, pageContext: pageContext),
    ),
    settings: const SheetRouteSettings(
      sheetSize: SheetSize.expanded,
      padChild: false,
    ),
  );
}

class _BranchActionsSheetBody extends StatefulWidget {
  const _BranchActionsSheetBody({
    required this.branch,
    required this.pageContext,
  });

  final BranchEntity branch;
  final BuildContext pageContext;

  @override
  State<_BranchActionsSheetBody> createState() =>
      _BranchActionsSheetBodyState();
}

class _BranchActionsSheetBodyState extends State<_BranchActionsSheetBody> {
  String? _pendingStatusBranchId;

  BranchEntity _branchFromState(BranchesState state) {
    for (final branch in state.branches) {
      if (branch.id == widget.branch.id) return branch;
    }
    return widget.branch;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BranchesBloc, BranchesState>(
      listenWhen: (previous, current) =>
          previous.actionFailure != current.actionFailure ||
          previous.branches != current.branches,
      listener: (context, state) {
        if (_pendingStatusBranchId == widget.branch.id) {
          setState(() => _pendingStatusBranchId = null);
        }
      },
      builder: (context, state) {
        final branch = _branchFromState(state);
        final underMaintenance = !branch.isAvailable;
        final isUpdatingStatus = _pendingStatusBranchId == branch.id;
        final iconColor = context.appColors.textPrimary;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: _BranchActionsHeader(branch: branch),
            ),
            SizedBox(height: AppSpacing.lg),
            AppTableRow(
              title: 'branches.actions.view_branch'.tr(),
              leading: AppTableLeading.icon,
              leadingIcon: _actionIcon(AppSvgs.branchView, iconColor),
              onTap: () {
                Navigator.of(context).pop();
                widget.pageContext.push(BranchRoutes.detailsFor(branch.id));
              },
            ),
            AppTableRow(
              title: 'branches.actions.set_under_maintenance'.tr(),
              leading: AppTableLeading.icon,
              leadingIcon: _actionIcon(AppSvgs.branchMaintenance, iconColor),
              trailing: AppTableTrailing.switchControl,
              switchValue: underMaintenance,
              switchLoading: isUpdatingStatus,
              onSwitchChanged: (value) => _onMaintenanceToggled(
                context: context,
                branch: branch,
                setUnderMaintenance: value,
              ),
            ),
            const AppDivider(),
            _DeleteBranchRow(
              onTap: () => _onDeletePressed(context, branch),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onMaintenanceToggled({
    required BuildContext context,
    required BranchEntity branch,
    required bool setUnderMaintenance,
  }) async {
    final bloc = context.read<BranchesBloc>();

    // Turning maintenance off → activate immediately.
    if (!setUnderMaintenance) {
      setState(() => _pendingStatusBranchId = branch.id);
      bloc.add(
        BranchStatusChangedEvent(
          branchId: branch.id,
          isAvailable: true,
        ),
      );
      return;
    }

    // Turning maintenance on → confirm first (Figma `1237:9608`).
    Navigator.of(context).pop();
    if (!widget.pageContext.mounted) return;

    final confirmed = await showAppPopover<bool>(
      context: widget.pageContext,
      title: 'branches.actions.maintenance_confirm_title'.tr(),
      description: 'branches.actions.maintenance_confirm_description'.tr(
        namedArgs: {'name': branch.branchName},
      ),
      imageLayout: AppDialogImageLayout.iconSmall,
      featureIconColor: AppFeatureIconColor.primary,
      featureIconSize: AppFeatureIconSize.xl,
      featureIconAsset: AppSvgs.branchMaintenance,
      actions: AppPopoverActions.dual,
      primaryLabel: 'branches.actions.maintenance_confirm'.tr(),
      secondaryLabel: 'branches.actions.cancel'.tr(),
      onPrimary: () =>
          Navigator.of(widget.pageContext, rootNavigator: true).pop(true),
      onSecondary: () =>
          Navigator.of(widget.pageContext, rootNavigator: true).pop(false),
    );

    if (confirmed == true && widget.pageContext.mounted) {
      widget.pageContext.read<BranchesBloc>().add(
        BranchStatusChangedEvent(
          branchId: branch.id,
          isAvailable: false,
        ),
      );
    }
  }

  Future<void> _onDeletePressed(
    BuildContext context,
    BranchEntity branch,
  ) async {
    Navigator.of(context).pop();
    if (!widget.pageContext.mounted) return;

    // Figma delete confirm (`340:13601`).
    final confirmed = await showAppPopover<bool>(
      context: widget.pageContext,
      title: 'branches.actions.delete_confirm_title'.tr(),
      description: 'branches.actions.delete_confirm_description'.tr(),
      imageLayout: AppDialogImageLayout.iconSmall,
      featureIconColor: AppFeatureIconColor.error,
      featureIconSize: AppFeatureIconSize.lg,
      featureIconTheme: AppFeatureIconTheme.lightCircleOutline,
      actions: AppPopoverActions.dual,
      primaryLabel: 'branches.actions.delete_confirm'.tr(),
      primaryDestructive: true,
      secondaryLabel: 'branches.actions.cancel'.tr(),
      onPrimary: () =>
          Navigator.of(widget.pageContext, rootNavigator: true).pop(true),
      onSecondary: () =>
          Navigator.of(widget.pageContext, rootNavigator: true).pop(false),
    );

    if (confirmed == true && widget.pageContext.mounted) {
      widget.pageContext.read<BranchesBloc>().add(
        BranchDeletedEvent(branch.id),
      );
    }
  }

  Widget _actionIcon(String assetPath, Color color) {
    return AppSvgPicture.asset(
      assetPath,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _BranchActionsHeader extends StatelessWidget {
  const _BranchActionsHeader({required this.branch});

  final BranchEntity branch;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: AppSvgPicture.asset(
            AppSvgs.branchStore,
            width: 28,
            height: 28,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branch.branchName,
                style: typography.title3.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'branches.actions.service_center'.tr(),
                style: typography.smallNormal.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeleteBranchRow extends StatelessWidget {
  const _DeleteBranchRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Material(
      color: colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 18,
          ),
          child: Row(
            children: [
              AppSvgPicture.asset(
                AppSvgs.trashBold,
                width: 24,
                height: 24,
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  'branches.actions.delete_branch'.tr(),
                  style: typography.regularNormal.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
