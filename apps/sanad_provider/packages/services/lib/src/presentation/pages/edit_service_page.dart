import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/constants/service_image_limits.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/usecases/update_provider_service_description_usecase.dart';
import 'package:services/src/presentation/bloc/edit_service/edit_service_bloc.dart';
import 'package:services/src/presentation/bloc/service_details/service_details_bloc.dart';
import 'package:services/src/presentation/bloc/service_images/service_images_bloc.dart';
import 'package:services/src/presentation/widgets/edit_service_form_body.dart';
import 'package:services/src/presentation/widgets/manage_service_images_section.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Edit Service screen — submits `PATCH /provider-services/{id}` (description
/// only) via [EditServiceBloc]. Reached from `ServiceRoutes.editFor(id)` with
/// no `extra` — the full service is fetched here via [ServiceDetailsBloc]
/// (the exact same read path `ServiceDetailsPage` uses, `GET
/// /provider-services/:id`), never trusting whatever entity the caller
/// happened to navigate with. The Services list's rows are summaries (may
/// carry only a thumbnail, not the full `images` array) — using one
/// directly here would show Edit with incomplete/stale data.
///
/// Image mutations (add/delete/set-primary), handled by
/// [ManageServiceImagesSection], are separate, immediately-committed
/// requests against their own endpoints, owned by [ServiceImagesBloc] — they
/// don't go through [EditServiceBloc]/`PATCH /provider-services/{id}`. The
/// inner content reads `ServiceImagesBloc.state.service` (rather than owning
/// a local copy) so it can pop the freshest entity back even when only
/// images changed and description Save was never pressed.
class EditServicePage extends StatefulWidget {
  const EditServicePage({required this.serviceId, super.key});

  final String serviceId;

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final _contentKey = GlobalKey<_EditServiceContentState>();
  final _hasUnsavedInput = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hasUnsavedInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _hasUnsavedInput,
      builder: (context, hasUnsaved, scaffold) => PopScope(
        canPop: !hasUnsaved,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _onBackPressed(context);
        },
        child: scaffold!,
      ),
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
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<ServiceDetailsBloc, ServiceDetailsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const AppSkeletonizer(
            enabled: true,
            child: _EditServiceSkeleton(),
          );
        }

        final service = state.service;
        if (service == null) {
          final display = failureErrorDisplay(state.failure);
          return Center(
            child: AppErrorState(
              style: display.isConnectivity
                  ? AppErrorStateStyle.network
                  : AppErrorStateStyle.generic,
              title: display.title,
              description: display.description,
              retryLabel: failureRetryLabel(),
              onRetry: display.isRetryable ? () => _fetch(context) : null,
            ),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<EditServiceBloc>()),
            BlocProvider(
              create: (_) => sl<MediaUploadBloc>(
                param1: const MediaUploadConfig(
                  maxFileSize: FileSizePolicy.maxBytes,
                  maxFiles: kMaxServiceImages,
                  allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
                ),
              ),
            ),
            BlocProvider(
              create: (_) => sl<ServiceImagesBloc>(param1: service),
            ),
          ],
          child: _EditServiceContent(
            key: _contentKey,
            service: service,
            onUnsavedChanged: (unsaved) => _hasUnsavedInput.value = unsaved,
          ),
        );
      },
    );
  }

  void _fetch(BuildContext context) {
    final serviceId = context.read<ServiceDetailsBloc>().state.serviceId;
    if (serviceId != null) {
      context.read<ServiceDetailsBloc>().add(
        ServiceDetailsFetchRequested(serviceId),
      );
    }
  }

  /// Before the service has loaded, there's nothing to discard — pop
  /// directly. Once loaded, delegate to the content's own discard-guard
  /// (which needs `ServiceImagesBloc`/the form's unsaved-input state, both
  /// only available once [_EditServiceContent] is mounted).
  Future<void> _onBackPressed(BuildContext context) async {
    final contentState = _contentKey.currentState;
    if (contentState == null) {
      if (context.canPop()) context.pop();
      return;
    }
    await contentState.handleBackPressed();
  }
}

/// Lightweight placeholder shapes shimmered via [AppSkeletonizer] — not a
/// reuse of the real form/image editor, which are bloc-wired and can't
/// exist before the fetch resolves.
class _EditServiceSkeleton extends StatelessWidget {
  const _EditServiceSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    Widget field(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: typography.smallNormal.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: typography
              .semiBold(typography.regularNormal)
              .copyWith(color: colors.textPrimary),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field(BoneMock.words(2), BoneMock.words(3)),
          SizedBox(height: AppSpacing.lg),
          field(BoneMock.words(2), BoneMock.words(2)),
          SizedBox(height: AppSpacing.lg),
          field(BoneMock.words(2), BoneMock.words(8)),
          SizedBox(height: AppSpacing.xl),
          Text(
            BoneMock.words(2),
            style: typography.smallNormal.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.disabled,
                        borderRadius: BorderRadius.circular(
                          AppDimension.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: AppSpacing.xxl),
          SizedBox(
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.disabled,
                borderRadius: BorderRadius.circular(AppDimension.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditServiceContent extends StatefulWidget {
  const _EditServiceContent({
    required this.service,
    required this.onUnsavedChanged,
    super.key,
  });

  final ProviderServiceEntity service;
  final ValueChanged<bool> onUnsavedChanged;

  @override
  State<_EditServiceContent> createState() => _EditServiceContentState();
}

class _EditServiceContentState extends State<_EditServiceContent> {
  final _formBodyKey = GlobalKey<EditServiceFormBodyState>();
  // Ephemeral UI-only state (does the form currently satisfy every
  // required field) — `ValueNotifier` + `ValueListenableBuilder` instead
  // of `setState`, per this package's zero-`setState` architecture rule.
  final ValueNotifier<bool> _isFormComplete = ValueNotifier(true);

  @override
  void dispose() {
    _isFormComplete.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditServiceBloc, EditServiceState>(
      listener: _handleEditServiceState,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EditServiceFormBody(
                    key: _formBodyKey,
                    service: widget.service,
                    onCompletenessChanged: (complete) =>
                        _isFormComplete.value = complete,
                    onUnsavedChanged: widget.onUnsavedChanged,
                  ),
                  SizedBox(height: AppSpacing.xl),
                  const ManageServiceImagesSection(),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: BlocBuilder<EditServiceBloc, EditServiceState>(
              builder: (context, state) => ValueListenableBuilder<bool>(
                valueListenable: _isFormComplete,
                builder: (context, isFormComplete, _) =>
                    AppButtonPresets.primary(
                      label: 'services.edit_service.save_button'.tr(),
                      onPressed: isFormComplete && !state.isSubmitting
                          ? _onSave
                          : null,
                      isLoading: state.isSubmitting,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Figma `4715:26609` — discard-unsaved-changes guard, scoped to this
  /// screen. Only guards the description text field — image mutations are
  /// already committed to the backend by the time they're reflected in
  /// `ServiceImagesBloc.state.service`, so there's nothing to "discard" for
  /// them; back navigation always returns whatever image state exists.
  ///
  /// Called by the parent `EditServicePage` once this content is mounted
  /// (see `_EditServicePageState._onBackPressed`).
  Future<void> handleBackPressed() async {
    final hasUnsaved = _formBodyKey.currentState?.hasUnsavedInput ?? false;
    if (!hasUnsaved) {
      if (context.canPop()) context.pop(_imagesResultOrNull(context));
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
      context.pop(_imagesResultOrNull(context));
    }
  }

  /// The current `ServiceImagesBloc` service if any image mutation
  /// happened this screen, else `null` (nothing to propagate).
  ProviderServiceEntity? _imagesResultOrNull(BuildContext context) {
    final current = context.read<ServiceImagesBloc>().state.service;
    return current != widget.service ? current : null;
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
      final updated =
          state.updatedService ??
          context.read<ServiceImagesBloc>().state.service;
      if (context.canPop()) context.pop(updated);
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
