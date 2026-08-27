import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Builds one row inside [AppSelectSheet].
///
/// [item] is the entity; [isSelected] reflects current checked state.
/// [onTap] toggles the item — pass it directly to the row widget's `onTap`
/// so the row's own InkWell handles the ripple (avoids double-ripple when the
/// row widget wraps its own InkWell, e.g. [AppTableRow]).
typedef SelectSheetItemBuilder<T> =
    Widget Function(
      BuildContext context,
      T item,
      bool isSelected,
      VoidCallback onTap,
    );

/// Returns true when [item] should be shown for the given [query].
typedef SelectSheetFilter<T> = bool Function(T item, String query);

/// Generic search-and-multi-select sheet body used by feature packages.
///
/// Items are provided either synchronously via [items] or asynchronously via
/// [loadItems]. The sheet handles loading, retry-on-failure, empty-state, and
/// confirm-button enable/disable automatically.
///
/// Chrome-free — pair with `SheetNavigator.push` (settings:
/// `SheetRouteSettings(title: ..., padChild: false)`); the surrounding
/// surface, radius, drag handle, and barrier come from `SheetNavigation`'s
/// own chrome.
///
/// Example:
/// ```dart
/// final result = await SheetNavigator.push<List<WorkerEntity>>(
///   context,
///   AppSelectSheet<WorkerEntity>(
///     confirmLabel: 'Confirm'.tr(),
///     searchHint: 'Search by name'.tr(),
///     getId: (w) => w.id,
///     searchFilter: (w, q) => w.fullName.toLowerCase().contains(q),
///     loadItems: () async { ... },
///     itemBuilder: (ctx, w, sel, onTap) => AppTableRow(title: w.fullName, onTap: onTap),
///   ),
///   settings: SheetRouteSettings(title: 'Select Workers'.tr(), padChild: false),
/// );
/// ```
class AppSelectSheet<T> extends StatefulWidget {
  const AppSelectSheet({
    super.key,
    required this.confirmLabel,
    required this.searchHint,
    required this.getId,
    required this.itemBuilder,
    required this.searchFilter,
    this.initialSelectedIds = const {},
    this.items,
    this.loadItems,
    this.retryLabel = 'Retry',
    this.emptyBuilder,
    this.errorTextBuilder,
    this.searchVariant = AppSearchFieldVariant.flat,
    this.maxHeightFraction = 0.55,
    this.singleSelect = false,
  }) : assert(
         items != null || loadItems != null,
         'Provide either items or loadItems.',
       );

  final String confirmLabel;
  final String searchHint;

  /// Extracts the stable id used for selection tracking.
  final String Function(T) getId;

  /// Builds one list row. Receives the entity and its current selection state.
  final SelectSheetItemBuilder<T> itemBuilder;

  /// Returns true when the item matches the search query.
  final SelectSheetFilter<T> searchFilter;

  /// Pre-selected item ids shown as checked on open.
  final Set<String> initialSelectedIds;

  /// Synchronous or pre-loaded item list. Mutually exclusive with [loadItems].
  final List<T>? items;

  /// Async loader called once on init. Mutually exclusive with [items].
  final Future<List<T>> Function()? loadItems;

  /// Label for the retry button shown on load failure.
  final String retryLabel;

  /// Override the empty state. Defaults to nothing (empty area).
  final Widget Function(BuildContext)? emptyBuilder;

  /// Extracts a human-readable error message from the exception.
  final String Function(Object error)? errorTextBuilder;

  final AppSearchFieldVariant searchVariant;

  /// Caps just the scrollable items region (as a fraction of screen height)
  /// so the pinned search field / confirm button never scroll off-sheet.
  final double maxHeightFraction;

  /// When `true`, tapping a row immediately pops the sheet with that single
  /// item selected — no checkbox state, no confirm button. Use for a
  /// single-select field (e.g. a searchable dropdown) instead of the default
  /// multi-select-with-confirm behaviour.
  final bool singleSelect;

  @override
  State<AppSelectSheet<T>> createState() => _AppSelectSheetState<T>();
}

class _AppSelectSheetState<T> extends State<AppSelectSheet<T>> {
  final _searchController = TextEditingController();
  final _selectedIds = <String>{};

  List<T> _allItems = const [];
  String _query = '';
  bool _isLoading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
    if (widget.items != null) {
      _allItems = widget.items!;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await widget.loadItems!();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _allItems = items;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  List<T> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _allItems;
    return _allItems.where((item) => widget.searchFilter(item, query)).toList();
  }

  void _toggle(String id) {
    if (widget.singleSelect) {
      final item = _allItems.firstWhere((item) => widget.getId(item) == id);
      Navigator.of(context).pop([item]);
      return;
    }
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _confirm() {
    final selected = _allItems
        .where((item) => _selectedIds.contains(widget.getId(item)))
        .toList();
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight =
        MediaQuery.sizeOf(context).height * widget.maxHeightFraction;

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
            hint: widget.searchHint,
            variant: widget.searchVariant,
            showMicIcon: false,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: _buildBody(),
          ),
        ),
        if (!widget.singleSelect) ...[
          const AppDivider(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: AppButton(
              label: widget.confirmLabel,
              onPressed: _selectedIds.isEmpty ? null : _confirm,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: AppLoadingIndicator());

    if (_error != null) {
      final message =
          widget.errorTextBuilder?.call(_error!) ?? _error.toString();
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
              SizedBox(height: AppSpacing.md),
              AppButtonPresets.outline(
                label: widget.retryLabel,
                onPressed: _load,
              ),
            ],
          ),
        ),
      );
    }

    final items = _filtered;
    if (items.isEmpty) {
      return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, __) => const AppDivider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = widget.getId(item);
        final isSelected = _selectedIds.contains(id);
        return widget.itemBuilder(context, item, isSelected, () => _toggle(id));
      },
    );
  }
}
