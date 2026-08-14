import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/presentation/widgets/add_service_ai_enhance_button.dart';

/// The Edit Service form's fields — prefilled from the [service] being
/// edited.
///
/// The new backend contract only allows editing the description
/// (`PATCH /provider-services/{id} {description}`). Catalog service name
/// and category are shown read-only. Images aren't resubmitted here either
/// — there is currently no UI to edit a service's images post-creation
/// (Service Details only previews them read-only).
class EditServiceFormBody extends StatefulWidget {
  const EditServiceFormBody({
    required this.service,
    required this.onCompletenessChanged,
    super.key,
  });

  final ProviderServiceEntity service;

  /// Called whenever every required field becomes filled/emptied.
  final ValueChanged<bool> onCompletenessChanged;

  @override
  State<EditServiceFormBody> createState() => EditServiceFormBodyState();
}

/// Public so `EditServicePage` can hold a
/// `GlobalKey<EditServiceFormBodyState>`.
class EditServiceFormBodyState extends State<EditServiceFormBody> {
  late final _descriptionController = TextEditingController(
    text: widget.service.description ?? '',
  );
  bool _wasComplete = false;

  /// Read by `EditServicePage` on submit.
  String get description => _descriptionController.text.trim();

  /// Read by `EditServicePage` to decide whether to show the
  /// discard-changes confirmation on back navigation.
  bool get hasUnsavedInput => description != (widget.service.description ?? '');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportCompleteness());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelectField(
          label: 'services.add_service.service_name_label'.tr(),
          value: widget.service.serviceName,
          onTap: null,
        ),
        SizedBox(height: AppSpacing.lg),
        AppSelectField(
          label: 'services.add_service.category_label'.tr(),
          value: widget.service.category.name,
          onTap: null,
        ),
        SizedBox(height: AppSpacing.lg),
        Stack(
          children: [
            AppTextField(
              label: 'services.add_service.description_label'.tr(),
              isRequired: true,
              hint: 'services.add_service.description_hint'.tr(),
              controller: _descriptionController,
              maxLines: 5,
              validator: _validateDescription,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (_) => _reportCompleteness(),
            ),
            PositionedDirectional(
              end: AppSpacing.xs,
              bottom: AppSpacing.lg,
              child: AddServiceAiEnhanceButton(),
            ),
          ],
        ),
      ],
    );
  }

  String? _validateDescription(String? value) {
    if (!LengthValidator.isValid(value, maxLength: 500)) {
      return 'services.add_service.description_length_error'.tr(
        namedArgs: {'max': '500'},
      );
    }
    return null;
  }

  void _reportCompleteness() {
    final isComplete =
        description.isNotEmpty &&
        LengthValidator.isValid(description, maxLength: 500);
    if (isComplete == _wasComplete) return;
    _wasComplete = isComplete;
    widget.onCompletenessChanged(isComplete);
  }
}
