import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/presentation/widgets/branch_manager_picker_field.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Result of a confirmed [ContactEditSheet] submission.
class ContactEditResult {
  const ContactEditResult({required this.branchPhone, this.manager});

  final String branchPhone;
  final BranchManagerEntity? manager;
}

/// Opens the Contact section editor. Pops `null` when dismissed without
/// saving, otherwise a [ContactEditResult] with the confirmed fields.
Future<ContactEditResult?> showContactEditSheet({
  required BuildContext context,
  required String initialPhone,
  BranchManagerEntity? initialManager,
}) {
  return SheetNavigator.push<ContactEditResult>(
    context,
    ContactEditSheet(
      initialPhone: initialPhone,
      initialManager: initialManager,
    ),
    settings: SheetRouteSettings(
      title: 'branches.details.section_contact'.tr(),
    ),
  );
}

/// Contact section editor — phone, manager. Shell-agnostic; pair with
/// [SheetNavigator] (see [showContactEditSheet]).
class ContactEditSheet extends StatefulWidget {
  const ContactEditSheet({
    required this.initialPhone,
    this.initialManager,
    super.key,
  });

  final String initialPhone;
  final BranchManagerEntity? initialManager;

  @override
  State<ContactEditSheet> createState() => _ContactEditSheetState();
}

class _ContactEditSheetState extends State<ContactEditSheet> {
  late final _phoneController = TextEditingController(
    text: widget.initialPhone,
  );
  BranchManagerEntity? _manager;

  @override
  void initState() {
    super.initState();
    _manager = widget.initialManager;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final phone = _phoneController.text.trim();
    return phone.isEmpty || UaePhoneValidator.isMobile(phone);
  }

  bool get _hasChanges =>
      _phoneController.text.trim() != widget.initialPhone.trim() ||
      _manager?.id != widget.initialManager?.id;

  /// Live inline error — the field opens pre-filled with the branch's saved
  /// (valid) phone, so this only surfaces once the user edits it into an
  /// invalid UAE mobile number (SAN-777).
  String? get _phoneError {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return null;
    return UaePhoneValidator.mobileValidationMessage(phone)?.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Phone field + save button rebuild only on controller changes, not
        // the whole sheet (previously the addListener fired setState on
        // every keystroke).
        ListenableBuilder(
          listenable: _phoneController,
          builder: (context, _) => AppPhoneField(
            label: 'branches.add_branch.branch_phone'.tr(),
            controller: _phoneController,
            hint: 'branches.add_branch.branch_phone_hint'.tr(),
            errorText: _phoneError,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        BranchManagerPickerField(
          selectedManager: _manager,
          onManagerSelected: (manager) => setState(() => _manager = manager),
        ),
        SizedBox(height: AppSpacing.xl),
        ListenableBuilder(
          listenable: _phoneController,
          builder: (context, _) => AppButton(
            label: 'branches.edit_branch.save_button'.tr(),
            onPressed: _hasChanges && _isValid ? _submit : null,
          ),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      ContactEditResult(
        branchPhone: _phoneController.text.trim(),
        manager: _manager,
      ),
    );
  }
}
