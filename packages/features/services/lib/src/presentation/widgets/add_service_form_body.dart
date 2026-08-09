import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/entities/service_entity.dart';
import 'package:services/src/presentation/models/mock_add_service_data.dart';
import 'package:services/src/presentation/widgets/add_service_images_field.dart';
import 'package:services/src/presentation/widgets/select_service_name_sheet.dart';
import 'package:shared_ui/shared_ui.dart';

/// The Add Service form's fields — UI-only, no create/category/catalog API.
///
/// Reports overall completeness via [onCompletenessChanged] so
/// `AddServicePage` can enable/disable the bottom Create button, mirroring
/// the local-state pattern used by `AddWorkerPage`/`WorkerFormBody` (no bloc
/// needed for form validity here).
class AddServiceFormBody extends StatefulWidget {
  /// Creates the Add Service form body.
  const AddServiceFormBody({
    required this.onCompletenessChanged,
    required this.onRequestNewService,
    super.key,
  });

  /// Called whenever every required field becomes filled/emptied.
  final ValueChanged<bool> onCompletenessChanged;

  /// Called when the user taps "Request New service" — either from the
  /// inline hint or from the Service Name "not found" sheet state.
  final VoidCallback onRequestNewService;

  @override
  State<AddServiceFormBody> createState() => AddServiceFormBodyState();
}

/// Public so `AddServicePage` can hold a `GlobalKey<AddServiceFormBodyState>`.
class AddServiceFormBodyState extends State<AddServiceFormBody> {
  final _descriptionController = TextEditingController();

  String? _category;
  ServiceEntity? _service;
  bool _wasComplete = false;

  @override
  void dispose() {
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
          AppSelectField(
            label: 'services.add_service.service_name_label'.tr(),
            isRequired: true,
            hint: 'services.add_service.service_name_hint'.tr(),
            value: _service?.name,
            onTap: _pickServiceName,
          ),
          if (_category != null) ...[
            SizedBox(height: AppSpacing.sm),
            AppInlineLinkText(
              text: 'services.add_service.inline_not_found_prefix'.tr(),
              linkText: 'services.add_service.inline_request_link'.tr(),
              onLinkTap: widget.onRequestNewService,
            ),
          ],
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'services.add_service.description_label'.tr(),
            isRequired: true,
            hint: 'services.add_service.description_hint'.tr(),
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

    setState(() {
      _category = selected.first;
      // Clear a previously chosen service when it no longer belongs to the
      // newly selected category.
      if (_service != null && _service!.category != _category) {
        _service = null;
      }
    });
    _reportCompleteness();
  }

  Future<void> _pickServiceName() async {
    final services = _category == null
        ? MockAddServiceData.servicesByCategory
        : MockAddServiceData.servicesFor(_category!);

    final selected = await showSelectServiceNameSheet(
      context: context,
      services: services,
      onRequestNewService: widget.onRequestNewService,
    );
    if (selected == null) return;

    setState(() => _service = selected);
    _reportCompleteness();
  }

  void _reportCompleteness() {
    final isComplete =
        _category != null &&
        _service != null &&
        _descriptionController.text.trim().isNotEmpty &&
        context.read<MediaUploadBloc>().state.uploadedCount > 0;

    if (isComplete == _wasComplete) return;
    _wasComplete = isComplete;
    widget.onCompletenessChanged(isComplete);
  }
}
