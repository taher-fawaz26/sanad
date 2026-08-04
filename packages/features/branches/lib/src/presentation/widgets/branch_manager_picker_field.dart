import 'dart:async';

import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/paginated_branches_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/get_branch_managers_usecase.dart';
import 'package:branches/src/presentation/widgets/branch_person_select_field.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

class BranchManagerPickerField extends StatelessWidget {
  const BranchManagerPickerField({
    required this.selectedManager,
    required this.onManagerSelected,
    super.key,
  });

  final BranchManagerEntity? selectedManager;
  final ValueChanged<BranchManagerEntity> onManagerSelected;

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
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await SheetNavigator.push<BranchManagerEntity>(
      context,
      _ManagerPickerSheet(
        title: 'branches.add_branch.branch_manager'.tr(),
        cancelLabel: 'branches.add_branch.cancel'.tr(),
        searchHint: 'branches.add_branch.manager_search_hint'.tr(),
        loadMoreLabel: 'branches.add_branch.load_more'.tr(),
      ),
      settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
    );
    if (selected != null) {
      onManagerSelected(selected);
    }
  }
}

class _ManagerPickerSheet extends StatefulWidget {
  const _ManagerPickerSheet({
    required this.title,
    required this.cancelLabel,
    required this.searchHint,
    required this.loadMoreLabel,
  });

  final String title;
  final String cancelLabel;
  final String searchHint;
  final String loadMoreLabel;

  @override
  State<_ManagerPickerSheet> createState() => _ManagerPickerSheetState();
}

class _ManagerPickerSheetState extends State<_ManagerPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  var _managers = <BranchManagerEntity>[];
  BranchPaginationMeta? _meta;
  var _isLoading = false;
  var _isLoadingMore = false;
  String? _query;

  // Incremented on every new search. Captured before each await so stale
  // responses from a previous query are silently discarded.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _loadManagers(page: 1, query: null, replace: true);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final text = _searchController.text.trim();
      final normalized = text.isEmpty ? null : text;
      if (normalized == _query) return;
      _loadManagers(page: 1, query: normalized, replace: true);
    });
  }

  Future<void> _loadManagers({
    required int page,
    required String? query,
    required bool replace,
  }) async {
    if (replace) {
      _generation++;
      setState(() {
        _isLoading = true;
        _query = query;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    final gen = _generation;
    final params = GetBranchManagersParams(query: query, page: page, limit: 20);
    final result = await sl<GetBranchManagersUseCase>()(params).run();

    if (!mounted || gen != _generation) return;

    result.fold(
      (_) => setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      }),
      (paginated) => setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _meta = paginated.meta;
        _managers = replace
            ? paginated.managers
            : mergeManagerPages(_managers, paginated.managers);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(widget.cancelLabel),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: AppTextField(
              controller: _searchController,
              label: '',
              hint: widget.searchHint,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: _isLoading
                ? const Center(child: AppLoadingIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount:
                        _managers.length + (_meta?.hasMore == true ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _managers.length) {
                        return Center(
                          child: _isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: AppLoadingIndicator(),
                                )
                              : TextButton(
                                  onPressed: () => _loadManagers(
                                    page: _meta!.currentPage + 1,
                                    query: _query,
                                    replace: false,
                                  ),
                                  child: Text(widget.loadMoreLabel),
                                ),
                        );
                      }
                      final manager = _managers[index];
                      return ListTile(
                        leading: AppAvatar(
                          initials: manager.initials,
                          size: AppAvatarSize.small,
                        ),
                        title: Text(manager.fullName),
                        onTap: () => Navigator.of(context).pop(manager),
                      );
                    },
                  ),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Appends [incoming] to [existing], skipping any manager whose ID is already
/// present. Visible for testing.
List<BranchManagerEntity> mergeManagerPages(
  List<BranchManagerEntity> existing,
  List<BranchManagerEntity> incoming,
) {
  final seen = existing.map((m) => m.id).toSet();
  return [...existing, ...incoming.where((m) => seen.add(m.id))];
}
