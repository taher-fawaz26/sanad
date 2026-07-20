import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:workers/src/domain/entities/branch_option_entity.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/presentation/widgets/branch_select_field.dart';
import 'package:workers/src/presentation/widgets/worker_type_select_field.dart';

/// Shared form body for Add Member and Edit Member — both screens are
/// >80% identical UI, so the fields live here; the pages own only initial
/// values, submit action, page title, and success/failure behavior.
class WorkerFormBody extends StatefulWidget {
  const WorkerFormBody({
    required this.formKey,
    required this.showValidationErrors,
    this.initialFullName,
    this.initialEmail,
    this.initialPhone,
    this.initialJobTitle,
    this.initialType,
    this.initialBranch,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final bool showValidationErrors;
  final String? initialFullName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialJobTitle;
  final WorkerType? initialType;
  final BranchOptionEntity? initialBranch;

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
    text: widget.initialPhone,
  );
  late final jobTitleController = TextEditingController(
    text: widget.initialJobTitle,
  );

  late WorkerType? type = widget.initialType;
  late BranchOptionEntity? branch = widget.initialBranch;

  bool get isTypeValid => type != null;

  String get fullName => fullNameController.text.trim();
  String? get email =>
      emailController.text.trim().isEmpty ? null : emailController.text.trim();
  String? get phone =>
      phoneController.text.trim().isEmpty ? null : phoneController.text.trim();
  String get jobTitle => jobTitleController.text.trim();

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    jobTitleController.dispose();
    super.dispose();
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
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return null;
              return EmailValidator.isValid(trimmed)
                  ? null
                  : 'workers.add_worker.validation_email'.tr();
            },
          ),
          SizedBox(height: AppSpacing.md),
          AppPhoneField(
            label: 'workers.add_worker.phone_label'.tr(),
            controller: phoneController,
            hint: 'workers.add_worker.phone_hint'.tr(),
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: jobTitleController,
            label: 'workers.add_worker.job_title_label'.tr(),
            hint: 'workers.add_worker.job_title_hint'.tr(),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'workers.add_worker.validation_required'.tr()
                : null,
          ),
          SizedBox(height: AppSpacing.md),
          WorkerTypeSelectField(
            selectedType: type,
            onTypeSelected: (value) => setState(() => type = value),
            errorText: widget.showValidationErrors && type == null
                ? 'workers.add_worker.validation_required'.tr()
                : null,
          ),
          SizedBox(height: AppSpacing.md),
          BranchSelectField(
            selectedBranch: branch,
            onBranchSelected: (value) => setState(() => branch = value),
          ),
        ],
      ),
    );
  }
}
