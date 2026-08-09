import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/presentation/widgets/request_new_service_form_body.dart';

/// Request New Service screen — UI-only.
///
/// Reached from Add Service's "Request a New Service" button and its
/// "Didn't find your service? Request New service" inline link. Only the
/// Images field is backed by a real integration (`media_upload`, reused
/// unmodified from Add Service); category/submit remain UI-only.
class RequestNewServicePage extends StatefulWidget {
  /// Creates the Request New Service screen.
  const RequestNewServicePage({super.key});

  @override
  State<RequestNewServicePage> createState() => _RequestNewServicePageState();
}

class _RequestNewServicePageState extends State<RequestNewServicePage> {
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
                child: AppButtonPresets.primary(
                  label: 'services.request_new_service.submit_button'.tr(),
                  onPressed: _isFormComplete ? _onSubmit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    // UI-only for now — request-service API is a documented follow-up.
  }
}
