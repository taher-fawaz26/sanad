import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/presentation/bloc/add_service/add_service_bloc.dart';
import 'package:services/src/presentation/widgets/add_service_images_field.dart';
import 'package:shared_ui/shared_ui.dart';

/// The Add Service form's fields.
///
/// "Add a Service" means adding a catalog service to the provider's own
/// offered services (`POST /provider-services`). Service Name is a
/// read-only picker backed by the real catalog (`GET /services`, owned by
/// [AddServiceBloc] — this widget only dispatches
/// [AddServiceCatalogRequested] and reads the resulting state, it never
/// resolves a use case itself) — the user only ever sees the catalog
/// service's name; category is derived from the selection and shown
/// read-only. There is no price on this contract.
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

  // Ephemeral UI-only state (the catalog-service selection and whether its
  // "required" error should show) — `ValueNotifier` + a `ListenableBuilder`
  // merging both, instead of `setState`, per this package's zero-`setState`
  // architecture rule.
  final ValueNotifier<CatalogServiceEntity?> _selectedService = ValueNotifier(
    null,
  );
  final ValueNotifier<bool> _showSelectionError = ValueNotifier(false);
  bool _wasComplete = false;

  /// Read by `AddServicePage` on submit — the catalog service id
  /// (`serviceId` in `CreateProviderServiceDto`).
  String? get serviceId => _selectedService.value?.id;
  String get description => _descriptionController.text.trim();

  /// Read by `AddServicePage` to decide whether to show the discard-changes
  /// confirmation on back navigation.
  bool get hasUnsavedInput =>
      _selectedService.value != null ||
      _descriptionController.text.trim().isNotEmpty;

  /// Validates the service-selection field, revealing its error text if
  /// nothing is selected. Called by `AddServicePage` on submit — the
  /// dropdown has no built-in `Form`/`validator` hook, so this mirrors
  /// `WorkerTypeSelectField`'s `showValidationErrors` pattern instead.
  bool validateSelection() {
    final isValid = _selectedService.value != null;
    if (!isValid) _showSelectionError.value = true;
    return isValid;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
              _selectedService,
              _showSelectionError,
            ]),
            builder: (context, _) {
              final selected = _selectedService.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSelectField(
                    label: 'services.add_service.service_name_label'.tr(),
                    isRequired: true,
                    hint: 'services.add_service.service_select_hint'.tr(),
                    value: selected?.name,
                    onTap: _pickService,
                    errorText: _showSelectionError.value && selected == null
                        ? 'services.add_service.service_required_error'.tr()
                        : null,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  AppInlineLinkText(
                    text: 'services.add_service.inline_not_found_prefix'.tr(),
                    linkText: 'services.add_service.inline_request_link'.tr(),
                    onLinkTap: widget.onRequestNewService,
                  ),
                  if (selected != null) ...[
                    SizedBox(height: AppSpacing.lg),
                    AppSelectField(
                      label: 'services.add_service.category_label'.tr(),
                      value: selected.category.name,
                      onTap: null,
                    ),
                  ],
                ],
              );
            },
          ),
          SizedBox(height: AppSpacing.lg),
          AppDescriptionField(
            label: 'services.add_service.description_label'.tr(),
            isRequired: true,
            hint: 'services.add_service.description_hint'.tr(),
            controller: _descriptionController,
            maxLines: 5,
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

  /// Service Name dropdown — Figma `5261:44387`. Backed by the real
  /// `GET /services` catalog, fetched by [AddServiceBloc] in response to
  /// [AddServiceCatalogRequested]. Only [CatalogServiceEntity.name] is
  /// shown to the user; the id is retained internally as `serviceId`.
  Future<void> _pickService() async {
    final bloc = context.read<AddServiceBloc>();
    final selected = await showAppSelectSheet<CatalogServiceEntity>(
      context: context,
      title: 'services.add_service.service_name_label'.tr(),
      searchHint: 'common.search_hint'.tr(),
      singleSelect: true,
      getId: (service) => service.id,
      searchFilter: (service, query) =>
          service.name.toLowerCase().contains(query),
      loadItems: () => _loadCatalog(bloc),
      errorTextBuilder: (e) => e is Failure ? e.message : e.toString(),
      retryLabel: 'common.retry'.tr(),
      itemBuilder: (context, service, isSelected, onTap) =>
          AppTableRow(title: service.name, onTap: onTap),
    );
    if (selected == null || selected.isEmpty) return;

    _selectedService.value = selected.first;
    _showSelectionError.value = false;
    _reportCompleteness();
  }

  /// Bridges [AppSelectSheet]'s pull-based `loadItems` contract onto
  /// [AddServiceBloc]'s event/state cycle: dispatches
  /// [AddServiceCatalogRequested] and awaits the resulting state — this
  /// widget only ever talks to the bloc, never to a use case.
  Future<List<CatalogServiceEntity>> _loadCatalog(AddServiceBloc bloc) async {
    bloc.add(const AddServiceCatalogRequested());
    final state = await bloc.stream.firstWhere(
      (s) => s.catalogStatus != AddServiceCatalogStatus.loading,
    );
    if (state.catalogStatus == AddServiceCatalogStatus.failure) {
      throw state.catalogFailure!;
    }
    return state.catalogItems;
  }

  String? _validateDescription(String? value) {
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
