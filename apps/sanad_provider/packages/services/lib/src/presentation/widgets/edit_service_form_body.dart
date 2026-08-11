import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';
import 'package:services/src/presentation/widgets/add_service_ai_enhance_button.dart';
import 'package:services/src/presentation/widgets/add_service_images_field.dart';
import 'package:shared_ui/shared_ui.dart';

/// The Edit Service form's fields — prefilled from the [service] being
/// edited.
///
/// Unlike Add Service, Name here is free text: the provider is renaming
/// their own already-created service, not picking a catalog entry (the
/// catalog-dropdown-for-name behavior is specific to creating a *new*
/// service). Category still loads from the real `GET /categories`.
class EditServiceFormBody extends StatefulWidget {
  const EditServiceFormBody({
    required this.service,
    required this.onCompletenessChanged,
    super.key,
  });

  final ServiceRecordEntity service;

  /// Called whenever every required field becomes filled/emptied.
  final ValueChanged<bool> onCompletenessChanged;

  @override
  State<EditServiceFormBody> createState() => EditServiceFormBodyState();
}

/// Public so `EditServicePage` can hold a
/// `GlobalKey<EditServiceFormBodyState>`.
class EditServiceFormBodyState extends State<EditServiceFormBody> {
  late final _nameController = TextEditingController(
    text: widget.service.name,
  );
  late final _descriptionController = TextEditingController(
    text: widget.service.description ?? '',
  );
  late final _priceController = TextEditingController(
    text: widget.service.price.toString(),
  );

  late String _categoryId = widget.service.category.id;
  late String _categoryName = widget.service.category.name;
  bool _wasComplete = false;

  /// Read by `EditServicePage` on submit.
  String get name => _nameController.text.trim();
  String? get description => _descriptionController.text.trim().isEmpty
      ? null
      : _descriptionController.text.trim();
  String get categoryId => _categoryId;
  num? get price => num.tryParse(_priceController.text.trim());

  /// Read by `EditServicePage` to decide whether to show the
  /// discard-changes confirmation on back navigation.
  bool get hasUnsavedInput =>
      name != widget.service.name ||
      categoryId != widget.service.category.id ||
      (description ?? '') != (widget.service.description ?? '') ||
      price != widget.service.price;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedExistingMedia());
  }

  void _seedExistingMedia() {
    if (!mounted || widget.service.media.isEmpty) return;
    context.read<MediaUploadBloc>().add(
      MediaUploadExistingItemsSeeded([
        for (final media in widget.service.media)
          MediaUploadItem.remote(mediaId: media.id, url: media.url),
      ]),
    );
  }

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
            value: _categoryName,
            onTap: _pickCategory,
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          Stack(
            children: [
              AppTextField(
                label: 'services.add_service.description_label'.tr(),
                hint: 'services.add_service.description_hint'.tr(),
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

    setState(() {
      _categoryId = selected.first.id;
      _categoryName = selected.first.name;
    });
    _reportCompleteness();
  }

  void _reportCompleteness() {
    final isComplete =
        _categoryId.isNotEmpty &&
        name.isNotEmpty &&
        price != null &&
        price! > 0;

    if (isComplete == _wasComplete) return;
    _wasComplete = isComplete;
    widget.onCompletenessChanged(isComplete);
  }
}
