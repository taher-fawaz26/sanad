import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/presentation/widgets/branch_type_select_field.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:maps/maps.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Result of a confirmed [BranchInfoEditSheet] submission.
class BranchInfoEditResult {
  const BranchInfoEditResult({
    required this.branchName,
    required this.branchType,
    this.city,
  });

  final String branchName;
  final BranchType branchType;

  /// `null` only if the branch has no city and the user didn't pick one.
  final CityEntity? city;
}

/// Opens the Branch Info section editor. Pops `null` when dismissed without
/// saving, otherwise a [BranchInfoEditResult] with the confirmed fields.
Future<BranchInfoEditResult?> showBranchInfoEditSheet({
  required BuildContext context,
  required String initialName,
  required BranchType initialType,
  CityEntity? initialCity,
}) {
  return SheetNavigator.push<BranchInfoEditResult>(
    context,
    BranchInfoEditSheet(
      initialName: initialName,
      initialType: initialType,
      initialCity: initialCity,
    ),
    settings: SheetRouteSettings(
      title: 'branches.details.section_branch_info'.tr(),
    ),
  );
}

/// Branch Info section editor — name, type, city. Shell-agnostic; pair with
/// [SheetNavigator] (see [showBranchInfoEditSheet]).
class BranchInfoEditSheet extends StatefulWidget {
  const BranchInfoEditSheet({
    required this.initialName,
    required this.initialType,
    this.initialCity,
    super.key,
  });

  final String initialName;
  final BranchType initialType;
  final CityEntity? initialCity;

  @override
  State<BranchInfoEditSheet> createState() => _BranchInfoEditSheetState();
}

class _BranchInfoEditSheetState extends State<BranchInfoEditSheet> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late BranchType _type;
  CityEntity? _city;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _city = widget.initialCity;
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      RequiredValidator.isValid(_nameController.text) &&
      BusinessNameValidator.isValid(_nameController.text) &&
      LengthValidator.isValid(_nameController.text, maxLength: 255);

  bool get _hasChanges =>
      _nameController.text.trim() != widget.initialName.trim() ||
      _type != widget.initialType ||
      _city?.id != widget.initialCity?.id;

  /// Live inline error — the field starts pre-filled with a name that
  /// already satisfies the backend contract, so this only surfaces once the
  /// user edits it into an invalid state.
  String? get _nameError {
    if (!RequiredValidator.isValid(_nameController.text)) {
      return 'branches.add_branch.branch_name_required'.tr();
    }
    if (!BusinessNameValidator.isValid(_nameController.text)) {
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
        AppTextField(
          controller: _nameController,
          label: 'branches.add_branch.branch_name'.tr(),
          hint: 'branches.add_branch.branch_name_hint'.tr(),
          errorText: _nameError,
        ),
        SizedBox(height: AppSpacing.md),
        BranchTypeSelectField(
          selectedType: _type,
          onTypeSelected: (type) => setState(() => _type = type),
        ),
        SizedBox(height: AppSpacing.md),
        CitySelectField(
          label: 'branches.add_branch.city'.tr(),
          hint: 'branches.add_branch.city_select_hint'.tr(),
          pickerTitle: 'branches.add_branch.city'.tr(),
          searchHint: 'branches.add_branch.city_search_hint'.tr(),
          emptyLabel: 'branches.add_branch.city_empty'.tr(),
          retryLabel: 'common.cancel'.tr(),
          selectedCity: _city,
          onCitySelected: (city) => setState(() => _city = city),
        ),
        SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'branches.edit_branch.save_button'.tr(),
          onPressed: _isValid && _hasChanges ? _submit : null,
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      BranchInfoEditResult(
        branchName: _nameController.text.trim(),
        branchType: _type,
        city: _city,
      ),
    );
  }
}
