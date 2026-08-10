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
                              ? _onSubmit
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

  void _onSubmit() {
    final formState = _formBodyKey.currentState;
    if (formState == null) return;

    final mediaIds = context
        .read<MediaUploadBloc>()
        .state
        .items
        .where((item) => item.isSuccess)
        .map((item) => item.mediaId)
        .whereType<String>()
        .toList();
    if (mediaIds.isEmpty) return;

    context.read<RequestNewServiceBloc>().add(
      RequestNewServiceSubmittedEvent(
        CreateServiceRequestParams(
          requestedServiceName: formState.requestedServiceName,
          requestedCategoryName: formState.requestedCategoryName,
          description: formState.description,
          mediaIds: mediaIds,
        ),
      ),
    );
  }

  void _handleState(BuildContext context, RequestNewServiceState state) {
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
