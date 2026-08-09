import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/presentation/widgets/add_service_form_body.dart';
import 'package:services/src/routes/service_routes.dart';

/// Add Service screen — UI-only.
///
/// No service-create, category, or catalog API calls happen here; only the
/// Images field is backed by a real integration (`media_upload`). Backend
/// wiring for category/catalog/create is a documented follow-up.
class AddServicePage extends StatefulWidget {
  /// Creates the Add Service screen.
  const AddServicePage({super.key});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formBodyKey = GlobalKey<AddServiceFormBodyState>();
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
                      _Header(
                        onRequestNewService: _navigateToRequestNewService,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      AddServiceFormBody(
                        key: _formBodyKey,
                        onCompletenessChanged: (complete) {
                          if (_isFormComplete == complete) return;
                          setState(() => _isFormComplete = complete);
                        },
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
                child: AppButtonPresets.primary(
                  label: 'services.add_service.create_button'.tr(),
                  onPressed: _isFormComplete ? _onCreate : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRequestNewService() {
    context.push(ServiceRoutes.requestNew);
  }

  void _onCreate() {
    // UI-only for now — service-create API is a documented follow-up.
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
