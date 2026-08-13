import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/domain/usecases/browse_catalog_usecase.dart';
import 'package:services/src/presentation/widgets/add_service_ai_enhance_button.dart';
import 'package:services/src/presentation/widgets/add_service_images_field.dart';
import 'package:shared_ui/shared_ui.dart';

/// The Add Service form's fields.
///
/// "Add a Service" means adding a catalog service to the provider's own
/// offered services (`POST /provider-services`). Service Name is a
/// read-only picker backed by the real catalog (`GET /services` via
/// [BrowseCatalogUseCase]) — the user only ever sees the catalog service's
/// name; category is derived from the selection and shown read-only.
/// There is no price on this contract.
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

  CatalogServiceEntity? _selectedService;
  bool _wasComplete = false;

  /// Read by `AddServicePage` on submit — the catalog service id
  /// (`serviceId` in `CreateProviderServiceDto`).
  String? get serviceId => _selectedService?.id;
  String get description => _descriptionController.text.trim();

  /// Read by `AddServicePage` to decide whether to show the discard-changes
  /// confirmation on back navigation.
  bool get hasUnsavedInput =>
      _selectedService != null || _descriptionController.text.trim().isNotEmpty;

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
          if (_selectedService != null) ...[
            SizedBox(height: AppSpacing.lg),
            AppSelectField(
              label: 'services.add_service.category_label'.tr(),
              value: _selectedService!.category.name,
              onTap: null,
            ),
          ],
          SizedBox(height: AppSpacing.lg),
          Stack(
            children: [
              AppTextField(
                label: 'services.add_service.description_label'.tr(),
                isRequired: true,
                hint: 'services.add_service.description_hint'.tr(),
                controller: _descriptionController,
                maxLines: 5,
                onChanged: (_) => _reportCompleteness(),
              ),
              PositionedDirectional(
                end: AppSpacing.xs,
                bottom: AppSpacing.lg,
                child: const AddServiceAiEnhanceButton(),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          const AddServiceImagesField(),
        ],
      ),
    );
  }

  /// Service Name dropdown — Figma `5261:44387`. Backed by the real
  /// `GET /services` catalog via [BrowseCatalogUseCase]. Only
  /// [CatalogServiceEntity.name] is shown to the user; the id is retained
  /// internally as `serviceId`.
  Future<void> _pickService() async {
    final selected = await showAppSelectSheet<CatalogServiceEntity>(
      context: context,
      title: 'services.add_service.service_name_label'.tr(),
      searchHint: 'services.select_service.search_hint'.tr(),
      singleSelect: true,
      getId: (service) => service.id,
      searchFilter: (service, query) =>
          service.name.toLowerCase().contains(query),
      loadItems: () async {
        final result = await sl<BrowseCatalogUseCase>()(
          const BrowseCatalogParams(limit: 100),
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
    final hasImage = context.read<MediaUploadBloc>().state.items.any(
      (item) => item.isSuccess,
    );
    final isComplete =
        _selectedService != null && description.isNotEmpty && hasImage;

    if (isComplete == _wasComplete) return;
    _wasComplete = isComplete;
    widget.onCompletenessChanged(isComplete);
  }
}
