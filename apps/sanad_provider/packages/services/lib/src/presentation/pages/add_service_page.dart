import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/constants/service_image_limits.dart';
import 'package:services/src/domain/usecases/create_provider_service_usecase.dart';
import 'package:services/src/presentation/bloc/add_service/add_service_bloc.dart';
import 'package:services/src/presentation/widgets/add_service_form_body.dart';
import 'package:services/src/routes/service_routes.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Add Service screen — submits `POST /provider-services` via
/// [AddServiceBloc].
class AddServicePage extends StatefulWidget {
  /// Creates the Add Service screen.
  const AddServicePage({super.key});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formBodyKey = GlobalKey<AddServiceFormBodyState>();
  // Ephemeral UI-only state (does the form currently satisfy every
  // required field) — `ValueNotifier` + `ValueListenableBuilder` instead
  // of `setState`, per this package's zero-`setState` architecture rule.
  final ValueNotifier<bool> _isFormComplete = ValueNotifier(false);

  @override
  void dispose() {
    _isFormComplete.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MediaUploadBloc>(
        param1: const MediaUploadConfig(
          maxFileSize: FileSizePolicy.maxBytes,
          maxFiles: kMaxServiceImages,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
        ),
      ),
      child: BlocListener<AddServiceBloc, AddServiceState>(
        listener: _handleAddServiceState,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _onBackPressed(context);
          },
          child: Scaffold(
            backgroundColor: context.appColors.surface,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppNavBar(
                    title: 'services.title'.tr(),
                    showBackButton: true,
                    onLeadingTap: () => _onBackPressed(context),
                    trailing: AppNotificationIcon(
                      hasUnread: true,
                      onTap: () {},
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            onRequestNewService: _navigateToRequestNewService,
                          ),
                          SizedBox(height: AppSpacing.lg),
                          AddServiceFormBody(
                            key: _formBodyKey,
                            onCompletenessChanged: (complete) =>
                                _isFormComplete.value = complete,
                            onRequestNewService: _navigateToRequestNewService,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    child: BlocBuilder<AddServiceBloc, AddServiceState>(
                      builder: (context, state) => ValueListenableBuilder<bool>(
                        valueListenable: _isFormComplete,
                        builder: (context, isFormComplete, _) =>
                            AppButtonPresets.primary(
                              label: 'services.add_service.create_button'.tr(),
                              onPressed: isFormComplete && !state.isSubmitting
                                  ? () => _onCreate(context)
                                  : null,
                              isLoading: state.isSubmitting,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToRequestNewService() {
    context.push(ServiceRoutes.requestNew);
  }

  /// Figma `4715:26609` — discard-unsaved-changes guard, scoped to this
  /// screen only (not a generic navigation interceptor).
  Future<void> _onBackPressed(BuildContext context) async {
    final hasUnsaved = _formBodyKey.currentState?.hasUnsavedInput ?? false;
    if (!hasUnsaved) {
      if (context.canPop()) context.pop();
      return;
    }

    final discard = await showConfirmationSheet(
      context: context,
      title: 'services.discard_confirm_title'.tr(),
      description: 'services.discard_confirm_description'.tr(),
      actionLabel: 'services.discard_confirm_action'.tr(),
      cancelLabel: 'services.discard_confirm_cancel'.tr(),
      actionIntent: AppButtonIntent.destructive,
    );

    if ((discard ?? false) && context.mounted && context.canPop()) {
      context.pop();
    }
  }

  /// [context] must be a descendant of the `BlocProvider<MediaUploadBloc>`
  /// created in [build] — e.g. the `BlocBuilder` context below, not
  /// `State.context`, which is an ancestor of that provider and can't see
  /// it.
  void _onCreate(BuildContext context) {
    final formState = _formBodyKey.currentState;
    if (formState == null) return;
    if (!formState.validateSelection()) return;
    final serviceId = formState.serviceId;
    if (serviceId == null) return;

    final imageIds = context
        .read<MediaUploadBloc>()
        .state
        .items
        .where((item) => item.isSuccess)
        .map((item) => item.mediaId)
        .whereType<String>()
        .toList();
    if (imageIds.isEmpty) return;

    context.read<AddServiceBloc>().add(
      AddServiceSubmittedEvent(
        CreateProviderServiceParams(
          serviceId: serviceId,
          description: formState.description,
          imageIds: imageIds,
        ),
      ),
    );
  }

  void _handleAddServiceState(BuildContext context, AddServiceState state) {
    if (state.status == RequestStatus.success) {
      if (context.canPop()) context.pop(true);
      return;
    }
    if (state.status == RequestStatus.failure && state.failure != null) {
      final display = failureErrorDisplay(state.failure);
      showAppSnackbar(
        context: context,
        title: display.title,
        caption: display.description,
        color: AppSnackbarColor.error,
        layout: AppSnackbarLayout.fullWidth,
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRequestNewService});

  final VoidCallback onRequestNewService;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: Text(
            'services.title'.tr(),
            style: typography.title3.copyWith(color: colors.textPrimary),
          ),
        ),
        AppButtonPresets.outline(
          label: 'services.add_service.request_new_service'.tr(),
          onPressed: onRequestNewService,
          size: AppButtonSize.small,
        ),
      ],
    );
  }
}
