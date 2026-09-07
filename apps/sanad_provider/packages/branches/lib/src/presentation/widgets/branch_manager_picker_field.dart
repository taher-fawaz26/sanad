import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/presentation/bloc/branch_managers/branch_managers_bloc.dart';
import 'package:branches/src/presentation/widgets/branch_person_select_field.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

class BranchManagerPickerField extends StatelessWidget {
  const BranchManagerPickerField({
    required this.selectedManager,
    required this.onManagerSelected,
    this.isRequired = false,
    this.errorText,
    super.key,
  });

  final BranchManagerEntity? selectedManager;
  final ValueChanged<BranchManagerEntity> onManagerSelected;

  /// When `true`, appends a red `*` after the label.
  final bool isRequired;

  /// Inline error message shown below the field (injected string).
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return BranchPersonSelectField(
      label: 'branches.add_branch.branch_manager'.tr(),
      value: selectedManager?.fullName,
      hint: 'branches.add_branch.branch_manager_hint'.tr(),
      avatar: selectedManager == null
          ? null
          : AppAvatar(
              initials: selectedManager!.initials,
              size: AppAvatarSize.small,
            ),
      onTap: () => _openPicker(context),
      isRequired: isRequired,
      errorText: errorText,
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await SheetNavigator.push<BranchManagerEntity>(
      context,
      BlocProvider<BranchManagersBloc>(
        create: (_) =>
            sl<BranchManagersBloc>()..add(const BranchManagersFetchEvent()),
        child: _ManagerPickerSheet(
          searchHint: 'branches.add_branch.manager_search_hint'.tr(),
        ),
      ),
      // Content-sized (the default) with the shared chrome (drag handle +
      // title) — same pattern as the worker select sheet. The body caps its
      // own scroll region so small result sets render a compact sheet while
      // large ones scroll internally.
      settings: SheetRouteSettings(
        title: 'branches.add_branch.branch_manager'.tr(),
        padChild: false,
      ),
    );
    if (selected != null) {
      onManagerSelected(selected);
    }
  }
}

/// Sheet body — Stateless outer, with a tiny inner Stateful just to own the
/// [TextEditingController]'s lifecycle (UI-ephemeral controller allowed per
/// state-management rules; all business state lives in [BranchManagersBloc]).
class _ManagerPickerSheet extends StatelessWidget {
  const _ManagerPickerSheet({required this.searchHint});

  final String searchHint;

  @override
  Widget build(BuildContext context) => _ManagerPickerBody(
    searchHint: searchHint,
  );
}

class _ManagerPickerBody extends StatefulWidget {
  const _ManagerPickerBody({required this.searchHint});

  final String searchHint;

  @override
  State<_ManagerPickerBody> createState() => _ManagerPickerBodyState();
}

class _ManagerPickerBodyState extends State<_ManagerPickerBody> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cap just the scrollable list region so the pinned search field never
    // scrolls off-sheet; the outer sheet is content-sized, so a short list
    // yields a compact sheet and a long one scrolls within this box (mirrors
    // AppSelectSheet.maxHeightFraction).
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.55;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: AppSearchField(
            controller: _searchController,
            variant: AppSearchFieldVariant.bordered,
            hint: widget.searchHint,
            showMicIcon: false,
            autofocus: true,
            onChanged: (value) => context.read<BranchManagersBloc>().add(
              BranchManagersSearchChangedEvent(value),
            ),
          ),
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: BlocBuilder<BranchManagersBloc, BranchManagersState>(
              builder: (context, state) => SanadPagedList<BranchManagerEntity>(
                state: toPagingState(state.pagination),
                shrinkWrap: true,
                fetchNextPage: () => context.read<BranchManagersBloc>().add(
                  const BranchManagersLoadMoreEvent(),
                ),
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                itemBuilder: (context, manager, index) => ListTile(
                  leading: AppAvatar(
                    initials: manager.initials,
                    size: AppAvatarSize.small,
                  ),
                  title: Text(manager.fullName),
                  onTap: () => Navigator.of(context).pop(manager),
                ),
                firstPageErrorIndicatorBuilder: (context) => _PickerMessage(
                  message:
                      state.firstPageError?.localizedMessage() ??
                      'errors.unknown'.tr(),
                  actionLabel: 'common.retry'.tr(),
                  onAction: () => context.read<BranchManagersBloc>().add(
                    const BranchManagersRefreshEvent(),
                  ),
                ),
                newPageErrorIndicatorBuilder: (context) => _PickerMessage(
                  message:
                      state.nextPageError?.localizedMessage() ??
                      'errors.unknown'.tr(),
                  actionLabel: 'common.retry'.tr(),
                  onAction: () => context.read<BranchManagersBloc>().add(
                    const BranchManagersLoadMoreEvent(),
                  ),
                ),
                noItemsFoundIndicatorBuilder: (context) => _PickerMessage(
                  message: 'branches.add_branch.no_managers_found'.tr(),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Centered message (+ optional action) for the picker's empty / error
/// slots — keeps the three ISP builders consistent and compact.
class _PickerMessage extends StatelessWidget {
  const _PickerMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.appTypography.regularNormal.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: AppSpacing.md),
              AppButtonPresets.outline(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
