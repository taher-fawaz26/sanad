import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/usecases/get_workers_usecase.dart';

/// Result returned when the user confirms worker selection.
class SelectWorkerResult {
  const SelectWorkerResult({required this.selectedWorkers});

  final List<WorkerEntity> selectedWorkers;
}

/// Figma `add worker` action sheet (`251:7333`).
///
/// Loads workers from [GetWorkersUseCase], supports multi-select with search,
/// and returns the confirmed selection.
Future<SelectWorkerResult?> showSelectWorkerActionSheet({
  required BuildContext context,
  Set<String> initialSelectedIds = const {},
}) {
  final colors = context.appColors;
  final typography = context.appTypography;
  final brightness = Theme.of(context).brightness;
  final spec = ActionSheetTokens.resolve(
    colors: colors,
    typography: typography,
    brightness: brightness,
  );

  return showModalBottomSheet<SelectWorkerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: spec.barrierColor,
    builder: (context) => _SelectWorkerActionSheet(
      initialSelectedIds: initialSelectedIds,
    ),
  );
}

class _SelectWorkerActionSheet extends StatefulWidget {
  const _SelectWorkerActionSheet({required this.initialSelectedIds});

  final Set<String> initialSelectedIds;

  @override
  State<_SelectWorkerActionSheet> createState() =>
      _SelectWorkerActionSheetState();
}

class _SelectWorkerActionSheetState extends State<_SelectWorkerActionSheet> {
  final _searchController = TextEditingController();
  final _selectedIds = <String>{};

  List<WorkerEntity> _workers = const [];
  String _query = '';
  bool _isLoading = true;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
    _loadWorkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final result = await sl<GetWorkersUseCase>()(const NoParams()).run();

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _failure = failure;
      }),
      (workers) => setState(() {
        _isLoading = false;
        _workers = workers;
      }),
    );
  }

  List<WorkerEntity> get _filteredWorkers {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _workers;
    return _workers
        .where(
          (worker) =>
              worker.fullName.toLowerCase().contains(query) ||
              worker.role.toLowerCase().contains(query),
        )
        .toList();
  }

  void _toggleWorker(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _confirm() {
    final selected = _workers
        .where((worker) => _selectedIds.contains(worker.id))
        .toList();
    Navigator.of(context).pop(SelectWorkerResult(selectedWorkers: selected));
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.55;

    return AppActionSheet(
      title: 'workers.select_worker.title'.tr(),
      showCancel: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: AppSearchField(
              controller: _searchController,
              hint: 'workers.select_worker.search_hint'.tr(),
              showMicIcon: false,
              showClearWhenFilled: true,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: _buildListBody(),
          ),
        ],
      ),
      footer: AppButton(
        label: 'workers.select_worker.confirm'.tr(),
        onPressed: _selectedIds.isEmpty ? null : _confirm,
      ),
    );
  }

  Widget _buildListBody() {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    if (_failure != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _failure!.message,
                textAlign: TextAlign.center,
                style: context.appTypography.regularNormal.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              AppButtonPresets.outline(
                label: 'workers.select_worker.retry'.tr(),
                onPressed: _loadWorkers,
              ),
            ],
          ),
        ),
      );
    }

    final workers = _filteredWorkers;
    if (workers.isEmpty) {
      final isSearch = _query.trim().isNotEmpty;
      return Center(
        child: AppIllustratedEmptyState(
          iconAsset: AppSvgs.users2,
          title: isSearch
              ? 'workers.select_worker.search_empty_title'.tr()
              : 'workers.select_worker.empty_title'.tr(),
          description: isSearch
              ? 'workers.select_worker.search_empty_description'.tr()
              : 'workers.select_worker.empty_description'.tr(),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: workers.length,
      separatorBuilder: (_, __) => const AppDivider(),
      itemBuilder: (context, index) {
        final worker = workers[index];
        final isSelected = _selectedIds.contains(worker.id);

        return AppTableRow(
          title: worker.fullName,
          caption: worker.role,
          leading: AppTableLeading.avatar,
          leadingAvatar: AppAvatar(
            initials: worker.initials,
            backgroundColor: context.appColors.primary,
            showStatusDot: true,
          ),
          trailing: AppTableTrailing.icon,
          trailingIcon: AppCheckbox(
            value: isSelected,
            onChanged: (_) => _toggleWorker(worker.id),
          ),
          onTap: () => _toggleWorker(worker.id),
        );
      },
    );
  }
}
