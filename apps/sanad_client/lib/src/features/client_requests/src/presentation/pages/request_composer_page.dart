import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/request_draft/request_draft_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_date_time_picker.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_location_picker.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/service_picker_sheet.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/submission_conflict_banner.dart';
import 'package:shared_ui/shared_ui.dart';

/// Builds a request and submits it for matching.
///
/// Two behaviours here are load-bearing and easy to regress:
///
/// * **Saving never requires a complete draft.** The backend validates nothing
///   but field shapes on create and update; completeness is enforced at submit.
/// * **A failed save or submit keeps everything the user typed.** Only a
///   successful response replaces the form state.
class RequestComposerPage extends StatelessWidget {
  /// Creates the composer.
  const RequestComposerPage({
    required this.buildBloc,
    required this.browseServices,
    super.key,
    this.requestId,
    this.onSubmitted,
  });

  /// Builds the draft bloc.
  final RequestDraftBloc Function() buildBloc;

  /// Reads the service catalogue for the picker.
  final BrowseCatalogueServicesUseCase browseServices;

  /// When set, the composer opens an existing request for editing.
  final String? requestId;

  /// Called with the request id once a submit succeeds.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final id = requestId;
    return BlocProvider<RequestDraftBloc>(
      create: (_) {
        final bloc = buildBloc();
        if (id != null) bloc.add(RequestDraftLoaded(id));
        return bloc;
      },
      child: _ComposerView(
        browseServices: browseServices,
        isEditing: id != null,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _ComposerView extends StatefulWidget {
  const _ComposerView({
    required this.browseServices,
    required this.isEditing,
    this.onSubmitted,
  });

  final BrowseCatalogueServicesUseCase browseServices;
  final bool isEditing;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_ComposerView> createState() => _ComposerViewState();
}

class _ComposerViewState extends State<_ComposerView> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  RequestDraftBloc get _bloc => context.read<RequestDraftBloc>();

  Future<void> _pickService() async {
    final service = await ServicePickerSheet.show(
      context,
      browseServices: widget.browseServices,
    );
    if (service == null || !mounted) return;
    _bloc.add(
      RequestDraftServiceChanged(
        serviceId: service.id,
        serviceName: service.name,
      ),
    );
  }

  Future<void> _pickLocation() async {
    final state = _bloc.state;
    final result = await pickRequestLocation(
      context,
      lat: state.lat,
      lng: state.lng,
      address: state.addressLine,
    );
    if (result == null || !mounted) return;
    _bloc.add(
      RequestDraftLocationChanged(
        lat: result.position.latitude,
        lng: result.position.longitude,
        addressLine: result.address,
      ),
    );
  }

  Future<void> _pickTime(DateTime? current) async {
    final picked = await pickRequestDateTime(context, initial: current);
    if (picked == null || !mounted) return;
    _bloc.add(RequestDraftPreferredAtChanged(picked));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocConsumer<RequestDraftBloc, RequestDraftState>(
      listenWhen: (a, b) =>
          a.saveStatus != b.saveStatus ||
          a.submitStatus != b.submitStatus ||
          a.note != b.note,
      listener: (context, state) {
        // Keep the note controller in step when the server response replaces
        // the form (first save, or loading an existing request).
        if (state.note != null && _note.text != state.note) {
          _note.text = state.note!;
        }
        if (state.saveStatus == RequestStatus.failure) {
          showAppErrorSnackbar(
            context: context,
            title:
                state.saveFailure?.localizedSafeMessage() ??
                'client_requests.error_title'.tr(),
          );
        }
        if (state.submitStatus == RequestStatus.failure &&
            state.submissionConflict == null) {
          // A structured conflict renders its own banner with a recovery
          // action; anything else is an ordinary error.
          showAppErrorSnackbar(
            context: context,
            title:
                state.submitFailure?.localizedSafeMessage() ??
                'client_requests.error_title'.tr(),
          );
        }
        if (state.saveStatus == RequestStatus.success && !state.isSubmitting) {
          showAppSnackbar(
            context: context,
            title: 'client_requests.draft_saved_toast'.tr(),
          );
        }
        if (state.submitStatus == RequestStatus.success) {
          showAppSnackbar(
            context: context,
            title: 'client_requests.submitted_toast'.tr(),
          );
          final id = state.requestId;
          if (id != null) widget.onSubmitted?.call(id);
        }
      },
      builder: (context, state) {
        final conflict = state.submissionConflict;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                AppNavBar(
                  title: widget.isEditing
                      ? 'client_requests.edit_title'.tr()
                      : 'client_requests.compose_title'.tr(),
                  showBackButton: true,
                  onLeadingTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: AppSkeletonizer(
                    enabled: state.loadStatus == RequestStatus.loading,
                    child: ListView(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      children: [
                        if (conflict != null) ...[
                          SubmissionConflictBanner(
                            conflict: conflict,
                            onChangeService: _pickService,
                            onChangeLocation: _pickLocation,
                            onPickAlternative: (start) => _bloc
                              ..add(RequestDraftPreferredAtChanged(start))
                              ..add(const RequestDraftSubmitted()),
                          ),
                          SizedBox(height: AppSpacing.lg),
                        ],
                        AppSelectField(
                          label: 'client_requests.service_label'.tr(),
                          value: state.serviceName,
                          hint: 'client_requests.service_placeholder'.tr(),
                          isRequired: true,
                          onTap: _pickService,
                        ),
                        SizedBox(height: AppSpacing.md),
                        AppSelectField(
                          label: 'client_requests.location_label'.tr(),
                          value:
                              state.addressLine ??
                              (state.hasLocation
                                  ? '${state.lat}, ${state.lng}'
                                  : null),
                          hint: 'client_requests.location_placeholder'.tr(),
                          isRequired: true,
                          onTap: _pickLocation,
                        ),
                        SizedBox(height: AppSpacing.md),
                        AppSelectField(
                          label: 'client_requests.time_label'.tr(),
                          value: state.preferredAt == null
                              ? null
                              : formatRequestDateTime(
                                  context,
                                  state.preferredAt!,
                                ),
                          hint: 'client_requests.time_placeholder'.tr(),
                          isRequired: true,
                          errorText: state.preferredAtError?.tr(),
                          onTap: () => _pickTime(state.preferredAt),
                        ),
                        SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _note,
                          label: 'client_requests.note_label'.tr(),
                          hint: 'client_requests.note_placeholder'.tr(),
                          maxLines: 4,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              RequestFieldLimits.requestNoteMaxLength,
                            ),
                          ],
                          onChanged: (value) =>
                              _bloc.add(RequestDraftNoteChanged(value)),
                        ),
                        SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  color: colors.white,
                  child: Column(
                    children: [
                      AppButton(
                        label: 'client_requests.submit'.tr(),
                        // Enabled only once the three fields submit requires
                        // are present. The server re-checks regardless.
                        onPressed: state.canSubmit && !state.isSubmitting
                            ? () => _bloc.add(const RequestDraftSubmitted())
                            : null,
                        isLoading: state.isSubmitting,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'client_requests.save_draft'.tr(),
                        // Always available: a partial draft is valid.
                        onPressed: state.isSaving || state.isSubmitting
                            ? null
                            : () => _bloc.add(const RequestDraftSaved()),
                        variant: AppButtonVariant.outline,
                        isLoading: state.isSaving && !state.isSubmitting,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
