import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/presentation/bloc/add_service/add_service_bloc.dart';
import 'package:services/src/presentation/widgets/add_service_images_field.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:text_optimization/text_optimization.dart';

/// The Add Service form's fields.
///
/// "Add a Service" means adding a catalog service to the provider's own
/// offered services (`POST /provider-services`). Category and Service are a
/// two-step dependency (SAN-577): the user picks a real category first
/// (`GET /categories`), which then scopes the Service picker to that
/// category's catalog services (`GET /services?categoryId=`) — both owned
/// by [AddServiceBloc] via [AddServiceCategoriesRequested] and
/// [AddServiceCatalogRequested]; this widget only dispatches events and
/// reads the resulting state, it never resolves a use case itself. Changing
/// the category invalidates any already-picked service. There is no price
/// on this contract.
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

  // Ephemeral UI-only state (category/service selection and whether each
  // field's "required" error should show) — `ValueNotifier` + a
  // `ListenableBuilder` merging all four, instead of `setState`, per this
  // package's zero-`setState` architecture rule.
  final ValueNotifier<CategoryRecordEntity?> _selectedCategory = ValueNotifier(
    null,
  );
  final ValueNotifier<bool> _showCategoryError = ValueNotifier(false);
  final ValueNotifier<CatalogServiceEntity?> _selectedService = ValueNotifier(
    null,
  );
  final ValueNotifier<bool> _showSelectionError = ValueNotifier(false);
  bool _wasComplete = false;

  /// Read by `AddServicePage` on submit — the catalog service id
  /// (`serviceId` in `CreateProviderServiceDto`). Category is selection
  /// context only; it is never sent to `POST /provider-services`.
  String? get serviceId => _selectedService.value?.id;
  String get description => _descriptionController.text.trim();

  /// Read by `AddServicePage` to decide whether to show the discard-changes
  /// confirmation on back navigation.
  bool get hasUnsavedInput =>
      _selectedCategory.value != null ||
      _selectedService.value != null ||
      _descriptionController.text.trim().isNotEmpty;

  /// Validates the category/service selection fields, revealing their error
  /// text if nothing is selected. Called by `AddServicePage` on submit —
  /// the dropdowns have no built-in `Form`/`validator` hook, so this
  /// mirrors `WorkerTypeSelectField`'s `showValidationErrors` pattern
  /// instead.
  ///
  /// A non-null [serviceId] can only ever occur once a category was picked
  /// (the Service field is disabled until then, and changing category
  /// clears any prior service — see [_pickCategory]), so validity reduces
  /// to whether a service is selected.
  bool validateSelection() {
    final hasCategory = _selectedCategory.value != null;
    final hasService = _selectedService.value != null;
    if (!hasCategory) _showCategoryError.value = true;
    if (!hasService) _showSelectionError.value = true;
    return hasService;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _selectedCategory.dispose();
    _showCategoryError.dispose();
    _selectedService.dispose();
    _showSelectionError.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MediaUploadBloc, MediaUploadState>(
      listener: (context, state) => _reportCompleteness(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([
              _selectedCategory,
              _showCategoryError,
              _selectedService,
              _showSelectionError,
            ]),
            builder: (context, _) {
              final selectedCategory = _selectedCategory.value;
              final selectedService = _selectedService.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSelectField(
                    label: 'services.add_service.category_label'.tr(),
                    isRequired: true,
                    hint: 'services.add_service.category_select_hint'.tr(),
                    value: selectedCategory?.name,
                    onTap: _pickCategory,
                    errorText:
                        _showCategoryError.value && selectedCategory == null
                        ? 'services.add_service.category_required_error'.tr()
                        : null,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  AppSelectField(
                    label: 'services.add_service.service_name_label'.tr(),
                    isRequired: true,
                    hint: selectedCategory == null
                        ? 'services.add_service.service_disabled_hint'.tr()
                        : 'services.add_service.service_select_hint'.tr(),
                    value: selectedService?.name,
                    enabled: selectedCategory != null,
                    onTap: selectedCategory == null ? null : _pickService,
                    errorText:
                        _showSelectionError.value && selectedService == null
                        ? 'services.add_service.service_required_error'.tr()
                        : null,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  AppInlineLinkText(
                    text: 'services.add_service.inline_not_found_prefix'.tr(),
                    linkText: 'services.add_service.inline_request_link'.tr(),
                    onLinkTap: widget.onRequestNewService,
                  ),
                ],
              );
            },
          ),
          SizedBox(height: AppSpacing.lg),
          AiEnhanceDescriptionField(
            label: 'services.add_service.description_label'.tr(),
            isRequired: true,
            hint: 'services.add_service.description_hint'.tr(),
            controller: _descriptionController,
            maxLength: 500,
            validator: _validateDescription,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (_) => _reportCompleteness(),
            aiActionLabel: 'common.enhance_with_ai'.tr(),
          ),
          SizedBox(height: AppSpacing.lg),
          const AddServiceImagesField(),
        ],
      ),
    );
  }

  /// Category dropdown — the first step of the SAN-577 two-step dependency.
  /// Backed by the real `GET /categories` list, fetched by [AddServiceBloc]
  /// in response to [AddServiceCategoriesRequested].
  Future<void> _pickCategory() async {
    final bloc = context.read<AddServiceBloc>();
    final selected = await SheetNavigator.push<List<CategoryRecordEntity>>(
      context,
      AppSelectSheet<CategoryRecordEntity>(
        confirmLabel: '',
        searchHint: 'common.search_hint'.tr(),
        singleSelect: true,
        getId: (category) => category.id,
        searchFilter: (category, query) =>
            category.name.toLowerCase().contains(query),
        loadItems: () => _loadCategories(bloc),
        errorTextBuilder: (e) => e is Failure ? e.message : e.toString(),
        retryLabel: 'common.retry'.tr(),
        itemBuilder: (context, category, isSelected, onTap) =>
            AppTableRow(title: category.name, onTap: onTap),
      ),
      settings: SheetRouteSettings(
        title: 'services.add_service.category_label'.tr(),
        padChild: false,
      ),
    );
    if (selected == null || selected.isEmpty) return;
    final category = selected.first;
    if (category.id == _selectedCategory.value?.id) return;

    _selectedCategory.value = category;
    _showCategoryError.value = false;
    // Changing category invalidates any previously chosen service — a
    // service belongs to exactly one category, so the old selection is no
    // longer valid and must never be submitted alongside a different
    // category (SAN-577).
    _selectedService.value = null;
    _reportCompleteness();
  }

  /// Bridges [AppSelectSheet]'s pull-based `loadItems` contract onto
  /// [AddServiceBloc]'s event/state cycle: dispatches
  /// [AddServiceCategoriesRequested] and awaits the resulting state — this
  /// widget only ever talks to the bloc, never to a use case.
  Future<List<CategoryRecordEntity>> _loadCategories(
    AddServiceBloc bloc,
  ) async {
    bloc.add(const AddServiceCategoriesRequested());
    final state = await bloc.stream.firstWhere(
      (s) => s.categoriesStatus != AddServiceCategoriesStatus.loading,
    );
    if (state.categoriesStatus == AddServiceCategoriesStatus.failure) {
      throw state.categoriesFailure!;
    }
    return state.categories;
  }

  /// Service Name dropdown — Figma `5261:44387`, scoped to whichever
  /// category is currently selected. Backed by the real
  /// `GET /services?categoryId=` catalog, fetched by [AddServiceBloc] in
  /// response to [AddServiceCatalogRequested]. Only
  /// [CatalogServiceEntity.name] is shown to the user; the id is retained
  /// internally as `serviceId`. Unreachable while no category is selected —
  /// see the disabled [AppSelectField] in [build].
  Future<void> _pickService() async {
    final category = _selectedCategory.value;
    if (category == null) return;
    final bloc = context.read<AddServiceBloc>();
    final selected = await SheetNavigator.push<List<CatalogServiceEntity>>(
      context,
      AppSelectSheet<CatalogServiceEntity>(
        confirmLabel: '',
        searchHint: 'common.search_hint'.tr(),
        singleSelect: true,
        getId: (service) => service.id,
        searchFilter: (service, query) =>
            service.name.toLowerCase().contains(query),
        loadItems: () => _loadCatalog(bloc, category.id),
        errorTextBuilder: (e) => e is Failure ? e.message : e.toString(),
        retryLabel: 'common.retry'.tr(),
        emptyBuilder: (context) => const _ServiceEmptyInCategoryState(),
        itemBuilder: (context, service, isSelected, onTap) =>
            AppTableRow(title: service.name, onTap: onTap),
      ),
      settings: SheetRouteSettings(
        title: 'services.add_service.service_name_label'.tr(),
        padChild: false,
      ),
    );
    if (selected == null || selected.isEmpty) return;

    _selectedService.value = selected.first;
    _showSelectionError.value = false;
    _reportCompleteness();
  }

  /// Bridges [AppSelectSheet]'s pull-based `loadItems` contract onto
  /// [AddServiceBloc]'s event/state cycle: dispatches
  /// [AddServiceCatalogRequested] scoped to [categoryId] and awaits the
  /// resulting state — this widget only ever talks to the bloc, never to a
  /// use case.
  Future<List<CatalogServiceEntity>> _loadCatalog(
    AddServiceBloc bloc,
    String categoryId,
  ) async {
    bloc.add(AddServiceCatalogRequested(categoryId));
    final state = await bloc.stream.firstWhere(
      (s) => s.catalogStatus != AddServiceCatalogStatus.loading,
    );
    if (state.catalogStatus == AddServiceCatalogStatus.failure) {
      throw state.catalogFailure!;
    }
    return state.catalogItems;
  }

  String? _validateDescription(String? value) {
    if (!MeaningfulTextValidator.isValid(value)) {
      return 'validation.meaningless_text'.tr();
    }
    if (!LengthValidator.isValid(value, maxLength: 500)) {
      return 'validation.length_max'.tr(
        namedArgs: {'max': '500'},
      );
    }
    return null;
  }

  void _reportCompleteness() {
    final uploadedCount = context
        .read<MediaUploadBloc>()
        .state
        .items
        .where((item) => item.isSuccess)
        .length;
    // `CreateProviderServiceDto.imageIds`: minItems 1, maxItems 6.
    final hasImage = CollectionSizeValidator.isValid(
      uploadedCount,
      minItems: 1,
      maxItems: 6,
    );
    final isComplete =
        _selectedService.value != null &&
        description.isNotEmpty &&
        LengthValidator.isValid(description, maxLength: 500) &&
        hasImage;

    if (isComplete == _wasComplete) return;
    _wasComplete = isComplete;
    widget.onCompletenessChanged(isComplete);
  }
}

/// Shown inside the Service picker sheet when the selected category has no
/// catalog services (SAN-577) — distinct from the page-level "no services
/// added yet" onboarding state: the provider has services, this category
/// just doesn't have any yet. The Category field stays fully changeable
/// behind this sheet.
class _ServiceEmptyInCategoryState extends StatelessWidget {
  const _ServiceEmptyInCategoryState();

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final iconSize = responsiveDimension(48);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgPicture.asset(
              AppSvgs.searchAlert,
              width: iconSize,
              height: iconSize,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'services.add_service.service_empty_in_category'.tr(),
              textAlign: TextAlign.center,
              style: typography
                  .semiBold(typography.regularNormal)
                  .copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
