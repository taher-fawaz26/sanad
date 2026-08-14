import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/usecases/update_provider_service_description_usecase.dart';
import 'package:services/src/presentation/bloc/edit_service/edit_service_bloc.dart';
import 'package:services/src/presentation/widgets/edit_service_form_body.dart';
import 'package:shared_ui/shared_ui.dart';

/// Edit Service screen — submits `PATCH /provider-services/{id}` (description
/// only) via [EditServiceBloc]. Reached from `ServiceRoutes.editFor` with the
/// [ProviderServiceEntity] being edited passed via the route `extra`.
class EditServicePage extends StatefulWidget {
  const EditServicePage({required this.service, super.key});

  final ProviderServiceEntity service;

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final _formBodyKey = GlobalKey<EditServiceFormBodyState>();
  bool _isFormComplete = true;

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditServiceBloc, EditServiceState>(
      listener: _handleEditServiceState,
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
                  title: 'services.edit_service.title'.tr(),
                  showBackButton: true,
                  onLeadingTap: () => _onBackPressed(context),
                  trailing: AppNotificationIcon(hasUnread: true, onTap: () {}),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: EditServiceFormBody(
                      key: _formBodyKey,
                      service: widget.service,
                      onCompletenessChanged: (complete) {
                        if (_isFormComplete == complete) return;
                        setState(() => _isFormComplete = complete);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  child: BlocBuilder<EditServiceBloc, EditServiceState>(
                    builder: (context, state) => AppButtonPresets.primary(
                      label: 'services.edit_service.save_button'.tr(),
                      onPressed: _isFormComplete && !state.isSubmitting
                          ? _onSave
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

  /// Figma `4715:26609` — same discard-unsaved-changes guard as Add Service,
  /// scoped to this screen.
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
      destructive: true,
    );

    if ((discard ?? false) && context.mounted && context.canPop()) {
      context.pop();
    }
  }

  void _onSave() {
    final formState = _formBodyKey.currentState;
    if (formState == null) return;

    context.read<EditServiceBloc>().add(
      EditServiceSubmittedEvent(
        UpdateProviderServiceDescriptionParams(
          id: widget.service.id,
          description: formState.description,
        ),
      ),
    );
  }

  void _handleEditServiceState(BuildContext context, EditServiceState state) {
    if (state.status == RequestStatus.success) {
      if (context.canPop()) context.pop(state.updatedService);
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
