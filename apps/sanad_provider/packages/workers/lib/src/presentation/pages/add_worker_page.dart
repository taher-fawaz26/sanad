import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';
import 'package:workers/src/presentation/bloc/add_worker/add_worker_bloc.dart';
import 'package:workers/src/presentation/widgets/worker_form_body.dart';

/// Figma `Add Member Team` (`1546:8469`).
class AddWorkerPage extends StatefulWidget {
  const AddWorkerPage({super.key});

  @override
  State<AddWorkerPage> createState() => _AddWorkerPageState();
}

class _AddWorkerPageState extends State<AddWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  final _formBodyKey = GlobalKey<WorkerFormBodyState>();

  bool _showValidationErrors = false;
  bool _isFormComplete = false;

  @override
  Widget build(BuildContext context) {
    return MutationListener<AddWorkerBloc, AddWorkerState>(
      status: (state) => state.status,
      title: (context) => 'workers.add_worker.submitting_title'.tr(),
      description: (context) =>
          'workers.add_worker.submitting_description'.tr(),
      onSuccess: (context, state) => _showSuccessPopover(),
      onFailure: (context, state) {
        if (state.failure != null) _showErrorSnackbar(state.failure!);
      },
      child: Scaffold(
        backgroundColor: context.appColors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavBar(
                title: 'workers.add_worker.title'.tr(),
                showBackButton: true,
                onLeadingTap: () => context.pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: WorkerFormBody(
                    key: _formBodyKey,
                    formKey: _formKey,
                    showValidationErrors: _showValidationErrors,
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
                child: BlocBuilder<AddWorkerBloc, AddWorkerState>(
                  builder: (context, state) => AppButton(
                    label: 'workers.add_worker.invite_button'.tr(),
                    onPressed: state.isLoading || !_isFormComplete
                        ? null
                        : _onSubmit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    setState(() => _showValidationErrors = true);

    final formBody = _formBodyKey.currentState!;
    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid || !formBody.isTypeValid || !formBody.isPhoneValid) return;

    context.read<AddWorkerBloc>().add(
      AddWorkerSubmitEvent(
        InviteWorkerParams(
          fullName: formBody.fullName,
          jobTitle: formBody.jobTitle,
          type: formBody.type!,
          email: formBody.email!,
          phone: formBody.phone!,
        ),
      ),
    );
  }

  void _showSuccessPopover() {
    showAppSuccessPopover<void>(
      context: context,
      title: 'workers.add_worker.success_title'.tr(),
      description: 'workers.add_worker.success_description'.tr(),
      primaryLabel: 'common.okay'.tr(),
    ).then((_) {
      // Signal the caller (worker list) that a worker was added so it can
      // refresh — see EH-S3-02 refresh convention.
      if (mounted) context.pop(true);
    });
  }

  void _showErrorSnackbar(Failure failure) {
    final message = failure.message.trim();
    final caption = message.isEmpty
        ? 'workers.add_worker.error_invitation_failed'.tr()
        : failure.localizedMessage();

    showAppErrorSnackbar(
      context: context,
      title: 'workers.add_worker.error_invitation_failed'.tr(),
      caption: caption,
    );
  }
}
