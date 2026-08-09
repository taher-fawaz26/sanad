import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/presentation/models/mock_add_service_data.dart';
import 'package:services/src/presentation/widgets/add_service_images_field.dart';
import 'package:shared_ui/shared_ui.dart';

/// The Request New Service form's fields — UI-only, no submit/category API.
///
/// Category and Images reuse the exact same fields/wiring as
/// `AddServiceFormBody`; Requested Service Name is a plain required text
/// field rather than the searchable catalog picker, since this screen exists
/// precisely for services the catalog doesn't have.
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
  final _descriptionController = TextEditingController();

  String? _category;
  bool _wasComplete = false;

  @override
  void dispose() {
    _serviceNameController.dispose();
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
          AppSelectField(
            label: 'services.add_service.category_label'.tr(),
            isRequired: true,
            hint: 'services.add_service.category_hint'.tr(),
            value: _category,
            onTap: _pickCategory,
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'services.request_new_service.service_name_label'.tr(),
            isRequired: true,
            hint: 'services.request_new_service.service_name_hint'.tr(),
            controller: _serviceNameController,
            onChanged: (_) => _reportCompleteness(),
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'services.request_new_service.description_label'.tr(),
            isRequired: true,
            hint: 'services.request_new_service.description_hint'.tr(),
            controller: _descriptionController,
            maxLines: 5,
            onChanged: (_) => _reportCompleteness(),
          ),
          SizedBox(height: AppSpacing.lg),
          AppFieldLabel(
            label: 'services.add_service.images_label'.tr(),
            isRequired: true,
          ),
          SizedBox(height: responsiveDimension(FieldTokens.labelGap)),
          const AddServiceImagesField(),
        ],
      ),
    );
  }

  Future<void> _pickCategory() async {
    final selected = await showAppSelectSheet<String>(
      context: context,
      title: 'services.add_service.category_label'.tr(),
      searchHint: 'services.add_service.search_hint'.tr(),
      singleSelect: true,
      getId: (category) => category,
      searchFilter: (category, query) => category.toLowerCase().contains(query),
      items: MockAddServiceData.categories,
      itemBuilder: (context, category, isSelected, onTap) =>
          AppTableRow(title: category, onTap: onTap),
    );
    if (selected == null || selected.isEmpty) return;

    setState(() => _category = selected.first);
    _reportCompleteness();
  }

  void _reportCompleteness() {
    final isComplete =
        _category != null &&
        _serviceNameController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        context.read<MediaUploadBloc>().state.uploadedCount > 0;

    if (isComplete == _wasComplete) return;
    _wasComplete = isComplete;
    widget.onCompletenessChanged(isComplete);
  }
}
