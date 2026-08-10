import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';
import 'package:services/src/presentation/widgets/add_service_images_field.dart';
import 'package:shared_ui/shared_ui.dart';

/// The Add Service form's fields.
///
/// Category is loaded from the real `GET /categories`; Service Name is a
/// free-text field (no catalog picker — the catalog concept was UI-only
/// mock data and is not part of the real `CreateServiceDto`). Reports
/// overall completeness via [onCompletenessChanged] so `AddServicePage` can
/// enable/disable the bottom Create button.
class AddServiceFormBody extends StatefulWidget {
  /// Creates the Add Service form body.
  const AddServiceFormBody({
    required this.onCompletenessChanged,
    required this.onRequestNewService,
    super.key,
  });

  /// Called whenever every required field becomes filled/emptied.
  final ValueChanged<bool> onCompletenessChanged;

  /// Called when the user taps "Request New service".
  final VoidCallback onRequestNewService;

  @override
  State<AddServiceFormBody> createState() => AddServiceFormBodyState();
}

/// Public so `AddServicePage` can hold a `GlobalKey<AddServiceFormBodyState>`.
class AddServiceFormBodyState extends State<AddServiceFormBody> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  CategoryRecordEntity? _category;
  bool _wasComplete = false;

  /// Read by `AddServicePage` on submit.
  String get name => _nameController.text.trim();
  String? get description => _descriptionController.text.trim().isEmpty
      ? null
      : _descriptionController.text.trim();
  String? get categoryId => _category?.id;
  num? get price => num.tryParse(_priceController.text.trim());

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
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
            value: _category?.name,
            onTap: _pickCategory,
          ),
          SizedBox(height: AppSpacing.sm),
          AppInlineLinkText(
            text: 'services.add_service.inline_not_found_prefix'.tr(),
            linkText: 'services.add_service.inline_request_link'.tr(),
            onLinkTap: widget.onRequestNewService,
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'services.add_service.service_name_label'.tr(),
            isRequired: true,
            hint: 'services.add_service.service_name_hint'.tr(),
            controller: _nameController,
            onChanged: (_) => _reportCompleteness(),
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'services.add_service.price_label'.tr(),
            isRequired: true,
            hint: 'services.add_service.price_hint'.tr(),
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                widthFactor: 1,
                child: Text(
                  'services.currency_aed'.tr(),
                  style: context.appTypography.regularNormal.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),
            ),
            onChanged: (_) => _reportCompleteness(),
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'services.add_service.description_label'.tr(),
            hint: 'services.add_service.description_hint'.tr(),
            controller: _descriptionController,
            maxLines: 5,
            onChanged: (_) => _reportCompleteness(),
          ),
          SizedBox(height: AppSpacing.lg),
          AppFieldLabel(label: 'services.add_service.images_label'.tr()),
          SizedBox(height: responsiveDimension(FieldTokens.labelGap)),
          const AddServiceImagesField(),
        ],
      ),
    );
  }

  Future<void> _pickCategory() async {
    final selected = await showAppSelectSheet<CategoryRecordEntity>(
      context: context,
      title: 'services.add_service.category_label'.tr(),
      searchHint: 'services.add_service.search_hint'.tr(),
      singleSelect: true,
      getId: (category) => category.id,
      searchFilter: (category, query) =>
          category.name.toLowerCase().contains(query),
      loadItems: () async {
        final result = await sl<GetCategoriesUseCase>()(
          const GetCategoriesParams(limit: 100),
        ).run();
        return result.fold((f) => throw f, (paged) => paged.items);
      },
      errorTextBuilder: (e) => e is Failure ? e.message : e.toString(),
      retryLabel: 'services.select_service.retry'.tr(),
      itemBuilder: (context, category, isSelected, onTap) =>
          AppTableRow(title: category.name, onTap: onTap),
    );
    if (selected == null || selected.isEmpty) return;

    setState(() => _category = selected.first);
    _reportCompleteness();
  }

  void _reportCompleteness() {
    final isComplete =
        _category != null &&
        _nameController.text.trim().isNotEmpty &&
        price != null &&
        price! > 0;

    if (isComplete == _wasComplete) return;
    _wasComplete = isComplete;
    widget.onCompletenessChanged(isComplete);
  }
}
