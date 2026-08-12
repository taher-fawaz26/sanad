import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';
import 'package:services/src/presentation/widgets/add_service_ai_enhance_button.dart';
import 'package:services/src/presentation/widgets/add_service_images_field.dart';
import 'package:shared_ui/shared_ui.dart';

/// The Request New Service form's fields.
///
/// Per the new contract (`POST /service-requests`), the service `name` is
/// still free text (this is the "not in catalog" case), but `categoryId`
/// is now a real category reference — a dropdown backed by
/// `GET /categories`, not free text. Images are optional (max 6).
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

  CategoryRecordEntity? _category;
  bool _wasComplete = false;

  String get name => _serviceNameController.text.trim();
  String? get categoryId => _category?.id;
  String get description => _descriptionController.text.trim();

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
          AppTextField(
            label: 'services.request_new_service.service_name_label'.tr(),
            isRequired: true,
            hint: 'services.request_new_service.service_name_hint'.tr(),
            controller: _serviceNameController,
            onChanged: (_) => _reportCompleteness(),
          ),
          SizedBox(height: AppSpacing.lg),
          AppSelectField(
            label: 'services.request_new_service.category_name_label'.tr(),
            isRequired: true,
            hint: 'services.request_new_service.category_name_hint'.tr(),
            value: _category?.name,
            onTap: _pickCategory,
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

  Future<void> _pickCategory() async {
    final selected = await showAppSelectSheet<CategoryRecordEntity>(
      context: context,
      title: 'services.request_new_service.category_name_label'.tr(),
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
        name.isNotEmpty && categoryId != null && description.isNotEmpty;

    if (isComplete == _wasComplete) return;
    _wasComplete = isComplete;
    widget.onCompletenessChanged(isComplete);
  }
}
