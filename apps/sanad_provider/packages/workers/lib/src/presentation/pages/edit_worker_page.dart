import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/domain/usecases/update_worker_usecase.dart';
import 'package:workers/src/presentation/bloc/edit_worker/edit_worker_bloc.dart';
import 'package:workers/src/presentation/widgets/worker_form_body.dart';

/// Figma `Edit Member Team` (`1616:12896`).
class EditWorkerPage extends StatefulWidget {
  const EditWorkerPage({required this.worker, super.key});

  final WorkerEntity worker;

  @override
  State<EditWorkerPage> createState() => _EditWorkerPageState();
}

class _EditWorkerPageState extends State<EditWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  final _formBodyKey = GlobalKey<WorkerFormBodyState>();

  bool _showValidationErrors = false;

  bool get _isTypeReadOnly {
    final workerType = WorkerType.fromApiString(widget.worker.role);
    if (workerType == WorkerType.manager) return true;
    return widget.worker.assignedBranches.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MutationListener<EditWorkerBloc, EditWorkerState>(
      status: (state) => state.status,
      title: (context) => 'workers.edit_worker.submitting_title'.tr(),
      description: (context) =>
          'workers.edit_worker.submitting_description'.tr(),
      onSuccess: (context, state) => _showSuccessPopover(state.updatedWorker),
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
                title: 'workers.edit_worker.title'.tr(),
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
                    initialFullName: widget.worker.fullName,
                    initialEmail: widget.worker.email,
                    initialPhone: widget.worker.phone,
                    initialJobTitle: widget.worker.jobTitle,
                    initialType: WorkerType.fromApiString(widget.worker.role),
                    requireContact: false,
                    emailReadOnly: true,
                    typeReadOnly: _isTypeReadOnly,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: BlocBuilder<EditWorkerBloc, EditWorkerState>(
                  builder: (context, state) => AppButton(
                    label: 'common.save'.tr(),
                    onPressed: state.isLoading ? null : _onSubmit,
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

    if (!isFormValid || !formBody.isTypeValid) return;

    context.read<EditWorkerBloc>().add(
      EditWorkerSubmitEvent(
        UpdateWorkerParams(
          id: widget.worker.id,
          fullName: formBody.fullName,
          jobTitle: formBody.jobTitle,
          type: formBody.type!,
          phone: formBody.phone,
        ),
      ),
    );
  }

  void _showSuccessPopover(WorkerEntity? updatedWorker) {
    showAppSuccessPopover<void>(
      context: context,
      title: 'workers.edit_worker.success_title'.tr(),
      description: 'workers.edit_worker.success_description'.tr(),
      primaryLabel: 'common.okay'.tr(),
    ).then((_) {
      if (mounted) context.pop(updatedWorker);
    });
  }

  void _showErrorSnackbar(Failure failure) {
    final message = failure.message.trim();
    final caption = message.isEmpty
        ? 'workers.edit_worker.error_update_failed'.tr()
        : failure.localizedMessage();

    showAppErrorSnackbar(
      context: context,
      title: 'workers.edit_worker.error_update_failed'.tr(),
      caption: caption,
    );
  }
}
