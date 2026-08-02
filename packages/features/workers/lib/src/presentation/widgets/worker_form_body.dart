import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/presentation/widgets/worker_type_select_field.dart';

/// Shared form body for Add Member and Edit Member — both screens are
/// >80% identical UI, so the fields live here; the pages own only initial
/// values, submit action, page title, and success/failure behavior.
///
/// The backend `CreateInvitationDto` requires both email and phone, while
/// `UpdateWorkerDto` cannot change email at all — hence [requireContact]
/// (Add) and [emailReadOnly] (Edit).
class WorkerFormBody extends StatefulWidget {
  const WorkerFormBody({
    required this.formKey,
    required this.showValidationErrors,
    this.initialFullName,
    this.initialEmail,
    this.initialPhone,
    this.initialJobTitle,
    this.initialType,
    this.requireContact = true,
    this.emailReadOnly = false,
    this.typeReadOnly = false,
    this.onCompletenessChanged,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final bool showValidationErrors;
  final String? initialFullName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialJobTitle;
  final WorkerType? initialType;

  /// When true (Add), email and phone are mandatory.
  final bool requireContact;

  /// When true (Edit), email is shown but cannot be changed server-side.
  final bool emailReadOnly;

  /// When true, worker type cannot be changed.
  final bool typeReadOnly;

  /// Fires when [WorkerFormBodyState.isComplete] changes.
  final ValueChanged<bool>? onCompletenessChanged;

  @override
  State<WorkerFormBody> createState() => WorkerFormBodyState();
}

class WorkerFormBodyState extends State<WorkerFormBody> {
  late final fullNameController = TextEditingController(
    text: widget.initialFullName,
  );
  late final emailController = TextEditingController(
    text: widget.initialEmail,
  );
  late final phoneController = TextEditingController(
    // Dial code is shown by [AppPhoneField]; keep national digits only.
    text: UaePhoneValidator.toNationalInput(widget.initialPhone),
  );
  late final jobTitleController = TextEditingController(
    text: widget.initialJobTitle,
  );

  late WorkerType? type = widget.initialType;

  bool _wasComplete = false;

  bool get isTypeValid => type != null;

  /// Phone is valid when contact is optional, or when it normalizes to a
  /// valid UAE number.
  bool get isPhoneValid => !widget.requireContact || phone != null;

  /// All required fields are filled (and contact fields are valid when
  /// [WorkerFormBody.requireContact] is true).
  bool get isComplete {
    if (fullName.isEmpty || jobTitle.isEmpty || type == null) return false;
    if (widget.requireContact) {
      if (_validateEmail(emailController.text) != null) return false;
      if (!isPhoneValid) return false;
    }
    return true;
  }

  String get fullName => fullNameController.text.trim();

  String? get email =>
      emailController.text.trim().isEmpty ? null : emailController.text.trim();

  /// Normalized E.164 (`+971…`) for API payloads, or null when empty/invalid.
  String? get phone {
    final raw = phoneController.text.trim();
    if (raw.isEmpty) return null;
    return UaePhoneValidator.normalize(raw);
  }

  String get jobTitle => jobTitleController.text.trim();

  @override
  void initState() {
    super.initState();
    fullNameController.addListener(_onFieldChanged);
    emailController.addListener(_onFieldChanged);
    phoneController.addListener(_onFieldChanged);
    jobTitleController.addListener(_onFieldChanged);
    _wasComplete = isComplete;
  }

  @override
  void dispose() {
    fullNameController
      ..removeListener(_onFieldChanged)
      ..dispose();
    emailController
      ..removeListener(_onFieldChanged)
      ..dispose();
    phoneController
      ..removeListener(_onFieldChanged)
      ..dispose();
    jobTitleController
      ..removeListener(_onFieldChanged)
      ..dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final complete = isComplete;
    if (complete == _wasComplete) return;
    _wasComplete = complete;
    widget.onCompletenessChanged?.call(complete);
  }

  /// Reserved demo domains the backend's email service (Resend in test mode)
  /// refuses to deliver to. Blocked at the form so the invitation cannot enter
  /// a "created but un-sendable" state.
  static const _reservedEmailDomains = {
    'example.com',
    'example.org',
    'example.net',
    'test.com',
  };

  String? _validateEmail(String? value) {
    if (widget.emailReadOnly) return null;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return widget.requireContact
          ? 'workers.add_worker.validation_required'.tr()
          : null;
    }
    if (!EmailValidator.isValid(trimmed)) {
      return 'workers.add_worker.validation_email'.tr();
    }
    final at = trimmed.lastIndexOf('@');
    if (at >= 0) {
      final domain = trimmed.substring(at + 1).toLowerCase();
      if (_reservedEmailDomains.contains(domain)) {
        return 'workers.add_worker.validation_reserved_domain'.tr();
      }
    }
    return null;
  }

  String? get _phoneErrorText {
    if (!widget.showValidationErrors || !widget.requireContact) return null;
    return isPhoneValid ? null : 'workers.add_worker.validation_required'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      autovalidateMode: widget.showValidationErrors
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: fullNameController,
            label: 'workers.add_worker.full_name_label'.tr(),
            hint: 'workers.add_worker.full_name_hint'.tr(),
            isRequired: true,
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'workers.add_worker.validation_required'.tr()
                : null,
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: emailController,
            label: 'workers.add_worker.email_label'.tr(),
            hint: 'workers.add_worker.email_hint'.tr(),
            keyboardType: TextInputType.emailAddress,
            readOnly: widget.emailReadOnly,
            enabled: !widget.emailReadOnly,
            isRequired: widget.requireContact,
            validator: _validateEmail,
          ),
          SizedBox(height: AppSpacing.md),
          AppPhoneField(
            label: 'workers.add_worker.phone_label'.tr(),
            controller: phoneController,
            hint: 'workers.add_worker.phone_hint'.tr(),
            isRequired: widget.requireContact,
            errorText: _phoneErrorText,
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: jobTitleController,
            label: 'workers.add_worker.job_title_label'.tr(),
            hint: 'workers.add_worker.job_title_hint'.tr(),
            isRequired: true,
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'workers.add_worker.validation_required'.tr()
                : null,
          ),
          SizedBox(height: AppSpacing.md),
          WorkerTypeSelectField(
            selectedType: type,
            isRequired: true,
            onTypeSelected: widget.typeReadOnly
                ? null
                : (value) {
                    setState(() => type = value);
                    _onFieldChanged();
                  },
            enabled: !widget.typeReadOnly,
            errorText: widget.showValidationErrors && type == null
                ? 'workers.add_worker.validation_required'.tr()
                : null,
          ),
        ],
      ),
    );
  }
}
