import 'dart:async';

import 'package:app_assets/app_assets.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/presentation/widgets/branch_empty_states.dart';
import 'package:branches/src/presentation/widgets/branch_list_item.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What the user did inside the search sheet, reported back through the
/// modal's result so navigation always happens after the sheet has fully
/// closed instead of racing its dismissal animation.
sealed class _SearchSheetResult {
  const _SearchSheetResult();
}

class _ViewBranch extends _SearchSheetResult {
  const _ViewBranch(this.branch);
  final BranchEntity branch;
}

class _StartAddBranch extends _SearchSheetResult {
  const _StartAddBranch();
}

/// Branch search — Option C bottom sheet (Figma `1514:7861`).
///
/// The main list's search field is a tap-to-open trigger only; all typing
/// and results happen inside this modal sheet, which shares the page's
/// existing [BranchesBloc] so filtering stays consistent. The search query
/// is always reset when the sheet closes, regardless of how it was
/// dismissed (Cancel, scrim tap, drag, back gesture, or picking a branch).
/// Selecting a branch or the empty-state's "Add Branch" action reports its
/// result through the sheet's return value — navigation only happens once
/// the sheet is fully gone.
Future<void> showBranchSearchSheet(BuildContext context) async {
  final bloc = context.read<BranchesBloc>();

  final result = await showAppModalSheet<_SearchSheetResult>(
    context: context,
    child: BlocProvider.value(
      value: bloc,
      child: const _BranchSearchSheetBody(),
    ),
  );

  bloc.add(const BranchesSearchChangedEvent(''));

  if (!context.mounted) return;
  switch (result) {
    case _ViewBranch(:final branch):
      unawaited(context.push(BranchRoutes.detailsFor(branch.id)));
    case _StartAddBranch():
      unawaited(context.push(BranchRoutes.add));
    case null:
      break;
  }
}

class _BranchSearchSheetBody extends StatefulWidget {
  const _BranchSearchSheetBody();

  @override
  State<_BranchSearchSheetBody> createState() => _BranchSearchSheetBodyState();
}

class _BranchSearchSheetBodyState extends State<_BranchSearchSheetBody> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: AppSearchField(
            controller: _controller,
            variant: AppSearchFieldVariant.bordered,
            hint: 'branches.search_hint'.tr(),
            showMicIcon: false,
            autofocus: true,
            onChanged: (value) => context.read<BranchesBloc>().add(
              BranchesSearchChangedEvent(value),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<BranchesBloc, BranchesState>(
            builder: (context, state) {
              final branches = state.filteredBranches;
              final hasQuery = state.searchQuery.trim().isNotEmpty;

              if (branches.isEmpty) {
                return Center(
                  child: hasQuery
                      ? BranchesSearchEmptyState(
                          query: state.searchQuery,
                          onClearSearch: () => Navigator.of(context).pop(),
                        )
                      : AppGenericEmptyState(
                          title: 'branches.empty_first_branch_title'.tr(),
                          description: 'branches.empty_first_branch_description'
                              .tr(),
                          actionLabel: 'branches.empty_first_branch_action'
                              .tr(),
                          onAction: () => Navigator.of(
                            context,
                          ).pop(const _StartAddBranch()),
                        ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                itemCount: branches.length,
                separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  return BranchListItem(
                    branch: branch,
                    onTap: () => Navigator.of(context).pop(_ViewBranch(branch)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
