import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/usecases/create_service_request_usecase.dart';
import 'package:services/src/presentation/bloc/request_new_service/request_new_service_bloc.dart';
import 'package:services/src/presentation/widgets/request_new_service_form_body.dart';
import 'package:services/src/routes/service_routes.dart';

/// Request New Service screen — submits `POST /service-requests` via
/// [RequestNewServiceBloc].
class RequestNewServicePage extends StatefulWidget {
  /// Creates the Request New Service screen.
  const RequestNewServicePage({super.key});

  @override
  State<RequestNewServicePage> createState() => _RequestNewServicePageState();
}

class _RequestNewServicePageState extends State<RequestNewServicePage> {
  final _formBodyKey = GlobalKey<RequestNewServiceFormBodyState>();
  bool _isFormComplete = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MediaUploadBloc>(
        param1: const MediaUploadConfig(
          maxFileSize: 5 * 1024 * 1024,
          // "Images are optional (max 6)" per this screen's own doc
          // comment above — was previously capped at 5.
          maxFiles: 6,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
        ),
      ),
      child: BlocListener<RequestNewServiceBloc, RequestNewServiceState>(
        listener: _handleState,
        child: Scaffold(
          backgroundColor: context.appColors.surface,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppNavBar(
                  title: 'services.title'.tr(),
                  showBackButton: true,
                  onLeadingTap: () {
                    if (context.canPop()) context.pop();
                  },
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
                        Text(
                          'services.request_new_service.title'.tr(),
                          style: context.appTypography.title3.copyWith(
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        AppAlert(
                          type: AppAlertType.warning,
                          message: 'services.request_new_service.warning_banner'
                              .tr(),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        RequestNewServiceFormBody(
                          key: _formBodyKey,
                          onCompletenessChanged: (complete) {
                            if (_isFormComplete == complete) return;
                            setState(() => _isFormComplete = complete);
                          },
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
                  child:
                      BlocBuilder<
                        RequestNewServiceBloc,
                        RequestNewServiceState
                      >(
                        builder: (context, state) => AppButtonPresets.primary(
                          label: 'services.request_new_service.submit_button'
                              .tr(),
                          onPressed: _isFormComplete && !state.isSubmitting
                              ? () => _onSubmit(context)
                              : null,
                          isLoading: state.isSubmitting,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [context] must be a descendant of the `BlocProvider<MediaUploadBloc>`
  /// created in [build] — e.g. the `BlocBuilder` context below, not
  /// `State.context`, which is an ancestor of that provider and can't see
  /// it.
  void _onSubmit(BuildContext context) {
    final formState = _formBodyKey.currentState;
    if (formState == null) return;
    if (!formState.validateCategory()) return;
    final categoryId = formState.categoryId;
    if (categoryId == null) return;

    final imageIds = context
        .read<MediaUploadBloc>()
        .state
        .items
        .where((item) => item.isSuccess)
        .map((item) => item.mediaId)
        .whereType<String>()
        .toList();

    context.read<RequestNewServiceBloc>().add(
      RequestNewServiceSubmittedEvent(
        CreateServiceRequestParams(
          name: formState.name,
          categoryId: categoryId,
          description: formState.description,
          imageIds: imageIds.isEmpty ? null : imageIds,
        ),
      ),
    );
  }

  void _handleState(BuildContext context, RequestNewServiceState state) {
    if (state.status == RequestStatus.success) {
      _showSubmittedPopover(context);
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

  /// Figma `4715:24606` — success popover shown after `POST
  /// /service-requests` succeeds, instead of silently popping back.
  void _showSubmittedPopover(BuildContext context) {
    showAppPopover<void>(
      context: context,
      title: 'services.request_submitted.title'.tr(),
      description: 'services.request_submitted.description'.tr(),
      imageLayout: AppDialogImageLayout.iconSmall,
      featureIconColor: AppFeatureIconColor.success,
      featureIconSize: AppFeatureIconSize.lg,
      primaryLabel: 'services.request_submitted.view_requests'.tr(),
      secondaryLabel: 'services.request_submitted.back_to_services'.tr(),
      barrierDismissible: false,
      onPrimary: () {
        Navigator.of(context, rootNavigator: true).pop();
        context.go(ServiceRoutes.list, extra: 1);
      },
      onSecondary: () {
        Navigator.of(context, rootNavigator: true).pop();
        context.go(ServiceRoutes.list);
      },
    );
  }
}
