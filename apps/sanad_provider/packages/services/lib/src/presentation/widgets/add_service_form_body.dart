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
import 'package:services/src/domain/usecases/get_services_list_usecase.dart';
import 'package:services/src/presentation/widgets/add_service_ai_enhance_button.dart';
import 'package:services/src/presentation/widgets/add_service_images_field.dart';
import 'package:shared_ui/shared_ui.dart';

/// The Add Service form's fields.
///
/// Category is loaded from the real `GET /categories`; Service Name is a
/// dropdown loaded from the real `GET /services` catalog via
/// [GetServicesListUseCase] — only the name is shown, the id is retained on
/// `serviceId` for later backend integration once `CreateServiceDto`
/// supports a catalog-service-id field. Reports overall completeness via
/// [onCompletenessChanged] so `AddServicePage` can enable/disable the
/// bottom Create button.
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
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  CategoryRecordEntity? _category;
  ServiceRecordEntity? _selectedService;
  bool _wasComplete = false;

  /// Read by `AddServicePage` on submit.
  String get name => _selectedService?.name ?? '';

  /// Retained for future backend integration — the real `CreateServiceDto`
  /// currently has no catalog-service-id field, only `name`.
  String? get serviceId => _selectedService?.id;
  String? get description => _descriptionController.text.trim().isEmpty
      ? null
      : _descriptionController.text.trim();
  String? get categoryId => _category?.id;
  num? get price => num.tryParse(_priceController.text.trim());

  /// Read by `AddServicePage` to decide whether to show the discard-changes
  /// confirmation on back navigation.
  bool get hasUnsavedInput =>
      _category != null ||
      _selectedService != null ||
      _priceController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty;

  @override
  void dispose() {
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
          SizedBox(height: AppSpacing.lg),
          AppSelectField(
            label: 'services.add_service.service_name_label'.tr(),
            isRequired: true,
            hint: 'services.add_service.service_select_hint'.tr(),
            value: _selectedService?.name,
            onTap: _pickService,
          ),
          SizedBox(height: AppSpacing.sm),
          AppInlineLinkText(
            text: 'services.add_service.inline_not_found_prefix'.tr(),
            linkText: 'services.add_service.inline_request_link'.tr(),
            onLinkTap: widget.onRequestNewService,
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

    setState(() => _category = selected.first);
    _reportCompleteness();
  }

  /// Service Name dropdown — Figma `5261:44387` shows the same trailing
  /// chevron as Category, i.e. Name of Service is a catalog picker too, not
  /// free text. Backed by the real `GET /services` catalog via
  /// [GetServicesListUseCase] — confirmed against the live OpenAPI spec.
  /// Only [ServiceRecordEntity.name] is shown; price/description/category/
  /// media from the response are never rendered in this picker.
  Future<void> _pickService() async {
    final selected = await showAppSelectSheet<ServiceRecordEntity>(
      context: context,
      title: 'services.add_service.service_name_label'.tr(),
      searchHint: 'services.select_service.search_hint'.tr(),
      singleSelect: true,
      getId: (service) => service.id,
      searchFilter: (service, query) =>
          service.name.toLowerCase().contains(query),
      loadItems: () async {
        final result = await sl<GetServicesListUseCase>()(
          const GetServicesListParams(limit: 100),
        ).run();
        return result.fold((f) => throw f, (paged) => paged.items);
      },
      errorTextBuilder: (e) => e is Failure ? e.message : e.toString(),
      retryLabel: 'services.select_service.retry'.tr(),
      itemBuilder: (context, service, isSelected, onTap) =>
          AppTableRow(title: service.name, onTap: onTap),
    );
    if (selected == null || selected.isEmpty) return;

    setState(() => _selectedService = selected.first);
    _reportCompleteness();
  }

  void _reportCompleteness() {
    final isComplete =
        _category != null &&
        _selectedService != null &&
        price != null &&
        price! > 0;

    if (isComplete == _wasComplete) return;
    _wasComplete = isComplete;
    widget.onCompletenessChanged(isComplete);
  }
}
