import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/presentation/widgets/add_service_ai_enhance_button.dart';
import 'package:services/src/presentation/widgets/add_service_images_field.dart';

/// The Request New Service form's fields.
///
/// Per `CreateServiceRequestDto`, there is no existing-category-id field —
/// the backend only accepts a free-text `requestedServiceName` and/or
/// `requestedCategoryName` (at least one of the two, "or both"), a
/// description, and 1-5 images. There is deliberately no "Category" picker
/// bound to the real category list here.
class RequestNewServiceFormBody extends StatefulWidget {
  /// Creates the Request New Service form body.
  const RequestNewServiceFormBody({
    required this.onCompletenessChanged,
    super.key,
  });

  /// Called whenever every required field becomes filled/emptied.
  final ValueChanged<bool> onCompletenessChanged;

  @override
  State<RequestNewServiceFormBody> createState() =>
      RequestNewServiceFormBodyState();
}

/// Public so `RequestNewServicePage` can hold a
/// `GlobalKey<RequestNewServiceFormBodyState>`.
class RequestNewServiceFormBodyState extends State<RequestNewServiceFormBody> {
  final _serviceNameController = TextEditingController();
  final _categoryNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _wasComplete = false;

  String? get requestedServiceName => _serviceNameController.text.trim().isEmpty
      ? null
      : _serviceNameController.text.trim();
  String? get requestedCategoryName =>
      _categoryNameController.text.trim().isEmpty
      ? null
      : _categoryNameController.text.trim();
  String get description => _descriptionController.text.trim();

  @override
  void dispose() {
    _serviceNameController.dispose();
    _categoryNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MediaUploadBloc, MediaUploadState>(
      listener: (context, state) => _reportCompleteness(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'services.request_new_service.service_name_label'.tr(),
            hint: 'services.request_new_service.service_name_hint'.tr(),
            controller: _serviceNameController,
            onChanged: (_) => _reportCompleteness(),
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'services.request_new_service.category_name_label'.tr(),
            hint: 'services.request_new_service.category_name_hint'.tr(),
            controller: _categoryNameController,
            onChanged: (_) => _reportCompleteness(),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'services.request_new_service.name_or_category_hint'.tr(),
            style: context.appTypography.smallNormal.copyWith(
              color: context.appColors.textMuted,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Stack(
            children: [
              AppTextField(
                label: 'services.request_new_service.description_label'.tr(),
                isRequired: true,
                hint: 'services.request_new_service.description_hint'.tr(),
                controller: _descriptionController,
                maxLines: 5,
                onChanged: (_) => _reportCompleteness(),
              ),
              PositionedDirectional(
                end: AppSpacing.md,
                bottom: AppSpacing.md,
                child: AddServiceAiEnhanceButton(),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          const AddServiceImagesField(),
        ],
      ),
    );
  }

  void _reportCompleteness() {
    final isComplete =
        (requestedServiceName != null || requestedCategoryName != null) &&
        description.isNotEmpty &&
        context.read<MediaUploadBloc>().state.uploadedCount > 0;

    if (isComplete == _wasComplete) return;
    _wasComplete = isComplete;
    widget.onCompletenessChanged(isComplete);
  }
}
