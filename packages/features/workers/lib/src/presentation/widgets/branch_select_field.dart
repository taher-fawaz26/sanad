import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:workers/src/data/datasources/branch_option_remote_data_source.dart';
import 'package:workers/src/domain/entities/branch_option_entity.dart';

/// Branch picker for the Add/Edit Member form.
///
/// Follows the `_ManagerPickerSheet` pattern from
/// `packages/features/branches` (search + list in a modal bottom sheet),
/// trimmed down (no pagination) since the branch list is small.
class BranchSelectField extends StatelessWidget {
  const BranchSelectField({
    required this.selectedBranch,
    required this.onBranchSelected,
    this.errorText,
    super.key,
  });

  final BranchOptionEntity? selectedBranch;
  final ValueChanged<BranchOptionEntity> onBranchSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AppSelectField(
      label: 'workers.add_worker.branch_label'.tr(),
      value: selectedBranch?.name,
      hint: 'workers.add_worker.branch_hint'.tr(),
      errorText: errorText,
      onTap: () => _openPicker(context),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<BranchOptionEntity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BranchPickerSheet(
        title: 'workers.add_worker.branch_label'.tr(),
        cancelLabel: 'workers.cancel'.tr(),
        searchHint: 'workers.search_hint'.tr(),
      ),
    );
    if (selected != null) onBranchSelected(selected);
  }
}

class _BranchPickerSheet extends StatefulWidget {
  const _BranchPickerSheet({
    required this.title,
    required this.cancelLabel,
    required this.searchHint,
  });

  final String title;
  final String cancelLabel;
  final String searchHint;

  @override
  State<_BranchPickerSheet> createState() => _BranchPickerSheetState();
}

class _BranchPickerSheetState extends State<_BranchPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  var _branches = <BranchOptionEntity>[];
  var _isLoading = true;
  Failure? _failure;
  String? _query;

  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _loadBranches(query: null);
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
      _loadBranches(query: normalized);
    });
  }

  Future<void> _loadBranches({required String? query}) async {
    _generation++;
    final gen = _generation;
    setState(() {
      _isLoading = true;
      _failure = null;
      _query = query;
    });

    final result = await sl<BranchOptionRemoteDataSource>()
        .getBranchOptions(search: query)
        .run();

    if (!mounted || gen != _generation) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _failure = failure;
      }),
      (branches) => setState(() {
        _isLoading = false;
        _branches = branches;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;

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
                Expanded(child: Text(widget.title, style: typography.title2)),
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
                : _failure != null
                ? Center(
                    child: Text(
                      _failure!.message.isNotEmpty
                          ? _failure!.message.tr()
                          : 'empty_states.server_error_title'.tr(),
                    ),
                  )
                : _branches.isEmpty
                ? Center(child: Text('workers.search_empty_title'.tr()))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _branches.length,
                    itemBuilder: (context, index) {
                      final branch = _branches[index];
                      return ListTile(
                        title: Text(branch.name),
                        onTap: () => Navigator.of(context).pop(branch),
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
