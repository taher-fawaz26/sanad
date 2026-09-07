import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/presentation/widgets/branch_type_select_field.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Result of a confirmed [BranchInfoEditSheet] submission.
class BranchInfoEditResult {
  const BranchInfoEditResult({
    required this.branchName,
    required this.branchType,
  });

  final String branchName;
  final BranchType branchType;
}

/// Opens the Branch Info section editor. Pops `null` when dismissed without
/// saving, otherwise a [BranchInfoEditResult] with the confirmed fields.
Future<BranchInfoEditResult?> showBranchInfoEditSheet({
  required BuildContext context,
  required String initialName,
  required BranchType initialType,
  String? cityDisplayName,
}) {
  return SheetNavigator.push<BranchInfoEditResult>(
    context,
    BranchInfoEditSheet(
      initialName: initialName,
      initialType: initialType,
      cityDisplayName: cityDisplayName,
    ),
    settings: SheetRouteSettings(
      title: 'branches.details.section_branch_info'.tr(),
    ),
  );
}

/// Branch Info section editor — name and type. City is displayed read-only
/// (derived server-side from the branch location).
class BranchInfoEditSheet extends StatefulWidget {
  const BranchInfoEditSheet({
    required this.initialName,
    required this.initialType,
    this.cityDisplayName,
    super.key,
  });

  final String initialName;
  final BranchType initialType;
  final String? cityDisplayName;

  @override
  State<BranchInfoEditSheet> createState() => _BranchInfoEditSheetState();
}

class _BranchInfoEditSheetState extends State<BranchInfoEditSheet> {
  late final _nameController = TextEditingController(text: widget.initialName);
  // Read-only city field: controller created once, disposed with the sheet
  // (previously constructed inside build() — leaked one per rebuild).
  late final _cityController = TextEditingController(
    text: widget.cityDisplayName ?? '',
  );
  late BranchType _type;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      RequiredValidator.isValid(_nameController.text) &&
      MeaningfulTextValidator.isValid(_nameController.text) &&
      LengthValidator.isValid(_nameController.text, maxLength: 255);

  bool get _hasChanges =>
      _nameController.text.trim() != widget.initialName.trim() ||
      _type != widget.initialType;

  /// Live inline error — the field starts pre-filled with a name that
  /// already satisfies the backend contract, so this only surfaces once the
  /// user edits it into an invalid state.
  String? get _nameError {
    if (!RequiredValidator.isValid(_nameController.text)) {
      return 'branches.add_branch.branch_name_required'.tr();
    }
    if (!MeaningfulTextValidator.isValid(_nameController.text)) {
      return 'validation.invalid_name'.tr();
    }
    if (!LengthValidator.isValid(_nameController.text, maxLength: 255)) {
      return 'branches.add_branch.branch_name_max_length_error'.tr(
        namedArgs: {'max': '255'},
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text field + save button rebuild only on controller changes, not
        // the whole sheet (previously the addListener fired setState on
        // every keystroke).
        ListenableBuilder(
          listenable: _nameController,
          builder: (context, _) => AppTextField(
            controller: _nameController,
            label: 'branches.add_branch.branch_name'.tr(),
            hint: 'branches.add_branch.branch_name_hint'.tr(),
            errorText: _nameError,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        BranchTypeSelectField(
          selectedType: _type,
          onTypeSelected: (type) => setState(() => _type = type),
        ),
        if (widget.cityDisplayName != null &&
            widget.cityDisplayName!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          // Read-only by contract, not by omission: the backend derives the
          // branch city from `locationPlaceId` and exposes no `cityId` to
          // set, so the city changes only by moving the map pin. The caption
          // says so, otherwise the disabled field reads as broken (SAN-774).
          AppTextField(
            controller: _cityController,
            label: 'branches.add_branch.city'.tr(),
            caption: 'branches.details.city_follows_location'.tr(),
            readOnly: true,
            enabled: false,
          ),
        ],
        SizedBox(height: AppSpacing.xl),
        ListenableBuilder(
          listenable: _nameController,
          builder: (context, _) => AppButton(
            label: 'branches.edit_branch.save_button'.tr(),
            onPressed: _isValid && _hasChanges ? _submit : null,
          ),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      BranchInfoEditResult(
        branchName: _nameController.text.trim(),
        branchType: _type,
      ),
    );
  }
}
