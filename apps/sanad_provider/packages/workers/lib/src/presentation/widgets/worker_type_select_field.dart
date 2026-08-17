import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:workers/src/domain/entities/worker_type.dart';

/// Worker type picker (Worker / Manager), following `BranchTypeSelectField`.
class WorkerTypeSelectField extends StatelessWidget {
  const WorkerTypeSelectField({
    required this.selectedType,
    required this.onTypeSelected,
    this.enabled = true,
    this.isRequired = false,
    this.errorText,
    super.key,
  });

  final WorkerType? selectedType;
  final ValueChanged<WorkerType>? onTypeSelected;
  final bool enabled;
  final bool isRequired;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AppSelectField(
      label: 'workers.add_worker.type_label'.tr(),
      value: selectedType == null ? null : _localizedLabel(selectedType!),
      hint: 'workers.add_worker.type_hint'.tr(),
      errorText: errorText,
      enabled: enabled,
      isRequired: isRequired,
      onTap: enabled ? () => _openPicker(context) : null,
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    await SheetNavigator.push<void>(
      context,
      AppActionList(
        items: WorkerType.values
            .map(
              (type) => AppActionSheetItem(
                label: _localizedLabel(type),
                onTap: () => onTypeSelected?.call(type),
              ),
            )
            .toList(),
      ),
      settings: SheetRouteSettings(
        title: 'workers.add_worker.type_label'.tr(),
        padChild: false,
      ),
    );
  }

  String _localizedLabel(WorkerType type) => switch (type) {
    WorkerType.worker => 'workers.add_worker.type_worker'.tr(),
    WorkerType.manager => 'workers.add_worker.type_manager'.tr(),
  };
}
