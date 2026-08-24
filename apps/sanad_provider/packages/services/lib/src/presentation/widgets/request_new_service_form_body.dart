import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/presentation/bloc/request_new_service/request_new_service_bloc.dart';
import 'package:services/src/presentation/widgets/add_service_images_field.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:text_optimization/text_optimization.dart';

/// The Request New Service form's fields.
///
/// Per the new contract (`POST /service-requests`), the service `name` is
/// still free text (this is the "not in catalog" case), but `categoryId`
/// is now a real category reference — a dropdown backed by
/// `GET /categories`, owned by [RequestNewServiceBloc] — this widget only
/// dispatches [RequestNewServiceCategoriesRequested] and reads the
/// resulting state, it never resolves a use case itself — not free text.
/// Images are optional (max 6).
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

  // Ephemeral UI-only state (the category selection and whether its
  // "required" error should show) — `ValueNotifier` + a `ListenableBuilder`
  // merging both, instead of `setState`, per this package's zero-`setState`
  // architecture rule.
  final ValueNotifier<CategoryRecordEntity?> _category = ValueNotifier(null);
  final ValueNotifier<bool> _showCategoryError = ValueNotifier(false);
  bool _wasComplete = false;

  String get name => _serviceNameController.text.trim();
  String? get categoryId => _category.value?.id;
  String get description => _descriptionController.text.trim();

  /// Validates the category-selection field, revealing its error text if
  /// nothing is selected. Called by `RequestNewServicePage` on submit —
  /// mirrors `AddServiceFormBodyState.validateSelection`.
  bool validateCategory() {
    final isValid = _category.value != null;
    if (!isValid) _showCategoryError.value = true;
    return isValid;
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _category.dispose();
    _showCategoryError.dispose();
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
            isRequired: true,
            hint: 'services.request_new_service.service_name_hint'.tr(),
            controller: _serviceNameController,
            validator: _validateName,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (_) => _reportCompleteness(),
          ),
          SizedBox(height: AppSpacing.lg),
          ListenableBuilder(
            listenable: Listenable.merge([_category, _showCategoryError]),
            builder: (context, _) => AppSelectField(
              label: 'services.request_new_service.category_name_label'.tr(),
              isRequired: true,
              hint: 'services.request_new_service.category_name_hint'.tr(),
              value: _category.value?.name,
              onTap: _pickCategory,
              errorText: _showCategoryError.value && _category.value == null
                  ? 'services.request_new_service.category_required_error'.tr()
                  : null,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          AiEnhanceDescriptionField(
            label: 'services.request_new_service.description_label'.tr(),
            isRequired: true,
            hint: 'services.request_new_service.description_hint'.tr(),
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

  Future<void> _pickCategory() async {
    final bloc = context.read<RequestNewServiceBloc>();
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
        title: 'services.request_new_service.category_name_label'.tr(),
        padChild: false,
      ),
    );
    if (selected == null || selected.isEmpty) return;

    _category.value = selected.first;
    _showCategoryError.value = false;
    _reportCompleteness();
  }

  /// Bridges [AppSelectSheet]'s pull-based `loadItems` contract onto
  /// [RequestNewServiceBloc]'s event/state cycle: dispatches
  /// [RequestNewServiceCategoriesRequested] and awaits the resulting
  /// state — this widget only ever talks to the bloc, never to a use case.
  Future<List<CategoryRecordEntity>> _loadCategories(
    RequestNewServiceBloc bloc,
  ) async {
    bloc.add(const RequestNewServiceCategoriesRequested());
    final state = await bloc.stream.firstWhere(
      (s) => s.categoriesStatus != RequestNewServiceCategoriesStatus.loading,
    );
    if (state.categoriesStatus == RequestNewServiceCategoriesStatus.failure) {
      throw state.categoriesFailure!;
    }
    return state.categories;
  }

  /// Per `CreateServiceRequestDto.name`: required, maxLength 255.
  String? _validateName(String? value) {
    if (!RequiredValidator.isValid(value)) {
      return 'services.request_new_service.name_required_error'.tr();
    }
    if (!BusinessNameValidator.isValid(value)) {
      return 'validation.invalid_name'.tr();
    }
    if (!LengthValidator.isValid(value, maxLength: 255)) {
      return 'validation.length_max'.tr(
        namedArgs: {'max': '255'},
      );
    }
    return null;
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
    final isComplete =
        name.isNotEmpty &&
        _validateName(_serviceNameController.text) == null &&
        categoryId != null &&
        description.isNotEmpty &&
        LengthValidator.isValid(description, maxLength: 500);

    if (isComplete == _wasComplete) return;
    _wasComplete = isComplete;
    widget.onCompletenessChanged(isComplete);
  }
}
