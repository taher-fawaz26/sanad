import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/presentation/services/worker_invite_roles_field.dart';
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

  /// The mandatory baseline role id for [type] plus any additional roles
  /// picked in the Roles field. Only populated on the Add form — see
  /// [WorkerFormBody.requireContact].
  List<String> _roleIds = const [];

  /// `false` until the Roles field resolves a valid mandatory-role
  /// selection. Existing members (Edit form) never render the field, so it
  /// starts `true` there — [isComplete] only consults it when
  /// [WorkerFormBody.requireContact] is set.
  bool _rolesValid = false;

  bool _wasComplete = false;

  bool get isTypeValid => type != null;

  /// Phone is valid when contact is optional, or when it's a genuine UAE
  /// mobile number — not merely non-empty (SAN-596: a landline-shaped
  /// 8-digit number like `50000000` must not read as "valid" here just
  /// because [UaePhoneValidator.normalize] can format it).
  bool get isPhoneValid =>
      !widget.requireContact ||
      UaePhoneValidator.isMobile(phoneController.text.trim());

  /// Role ids to submit with the invitation — the mandatory baseline role
  /// for [type] plus any additional roles picked. Empty outside the Add
  /// form.
  List<String> get roleIds => _roleIds;

  /// All required fields are filled (and contact fields are valid when
  /// [WorkerFormBody.requireContact] is true).
  bool get isComplete {
    if (fullName.isEmpty || type == null) return false;
    if (_validateFullName(fullNameController.text) != null) return false;
    if (widget.requireContact) {
      if (_validateEmail(emailController.text) != null) return false;
      if (!isPhoneValid) return false;
      if (!_rolesValid) return false;
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

  /// Mirrors the backend's `name` rule: letters, spaces, dashes, and
  /// apostrophes only — no digits or other punctuation (backend rejects with
  /// "...حروف ومسافات وشرطات وفواصل عليا فقط").
  ///
  /// Uses `PersonNameValidator(minWords: 1)`: a worker may legitimately be
  /// registered under a single name (e.g. "Ahmed"), so the shared 2-word
  /// default is relaxed here rather than forked into a local regex.
  String? _validateFullName(String? value) {
    if (!RequiredValidator.isValid(value)) {
      return 'validation.required'.tr();
    }
    final trimmed = value!.trim();
    if (!PersonNameValidator.isValid(trimmed, minWords: 1)) {
      return 'workers.add_worker.validation_name_format'.tr();
    }
    if (!LengthValidator.isValid(trimmed, minLength: 3, maxLength: 255)) {
      return 'validation.length_range'.tr(
        namedArgs: {'min': '3', 'max': '255'},
      );
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (widget.emailReadOnly) return null;
    if (!RequiredValidator.isValid(value)) {
      return widget.requireContact ? 'validation.required'.tr() : null;
    }
    final trimmed = value!.trim();
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

  /// Empty text is only an error when the field is required; a non-empty
  /// value that fails [UaePhoneValidator] gets its own distinct format
  /// error rather than being conflated with "required".
  ///
  /// Mobile-only (`mobileValidationMessage`, not `validationMessage`) —
  /// team members are contacted on a mobile number, and the backend rejects
  /// landline-shaped input for this endpoint (SAN-596: an 8-digit landline
  /// number like `50000000` was previously accepted client-side and only
  /// rejected after a failed save attempt).
  String? _validatePhone(String? _) {
    final raw = phoneController.text.trim();
    if (raw.isEmpty) {
      return widget.requireContact ? 'validation.required'.tr() : null;
    }
    return UaePhoneValidator.mobileValidationMessage(raw)?.tr();
  }

  /// `UpdateWorkerDto.jobTitle` / `CreateInvitationDto.jobTitle` are both
  /// optional (maxLength 255, not required) — so an empty job title is
  /// valid; only enforce the length limit when a value is present.
  String? _validateJobTitle(String? value) {
    if (!RequiredValidator.isValid(value)) return null;
    if (!LengthValidator.isValid(value, maxLength: 255)) {
      return 'validation.length_max'.tr(
        namedArgs: {'max': '255'},
      );
    }
    return null;
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
            validator: _validateFullName,
            // SAN-593: validate live as the user types, rather than only
            // after a failed submit attempt (`showValidationErrors`).
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: emailController,
            label: 'workers.add_worker.email_label'.tr(),
            hint: 'workers.add_worker.email_hint'.tr(),
            isLtr: true,
            keyboardType: TextInputType.emailAddress,
            readOnly: widget.emailReadOnly,
            enabled: !widget.emailReadOnly,
            isRequired: widget.requireContact,
            validator: _validateEmail,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          SizedBox(height: AppSpacing.md),
          AppPhoneField(
            label: 'workers.add_worker.phone_label'.tr(),
            controller: phoneController,
            hint: 'workers.add_worker.phone_hint'.tr(),
            isRequired: widget.requireContact,
            validator: _validatePhone,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: jobTitleController,
            label: 'workers.add_worker.job_title_label'.tr(),
            hint: 'workers.add_worker.job_title_hint'.tr(),
            validator: _validateJobTitle,
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                ? 'validation.required'.tr()
                : null,
          ),
          if (widget.requireContact && type != null) ...[
            SizedBox(height: AppSpacing.md),
            sl<WorkerInviteRolesField>().build(
              type: type!,
              onChanged: (selection) {
                setState(() {
                  _roleIds = selection.roleIds;
                  _rolesValid = selection.isValid;
                });
                _onFieldChanged();
              },
            ),
          ],
        ],
      ),
    );
  }
}
