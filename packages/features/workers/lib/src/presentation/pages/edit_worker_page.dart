import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  var _submittingDialogVisible = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditWorkerBloc, EditWorkerState>(
      listener: _onBlocStateChanged,
      child: Scaffold(
        backgroundColor: context.appColors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavBar(
                title: 'workers.edit_worker.title'.tr(),
                showBackButton: true,
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
                    label: 'workers.edit_worker.save_button'.tr(),
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
          email: formBody.email,
          phone: formBody.phone,
          branchId: formBody.branch?.id,
        ),
      ),
    );
  }

  void _onBlocStateChanged(BuildContext context, EditWorkerState state) {
    if (state.isLoading) {
      _showSubmittingDialog();
      return;
    }
    _dismissSubmittingDialog();

    if (state.isSuccess) {
      _showSuccessPopover(state.updatedWorker);
    } else if (state.hasError && state.failure != null) {
      _showErrorSnackbar(state.failure!);
    }
  }

  void _showSubmittingDialog() {
    if (_submittingDialogVisible) return;
    _submittingDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = dialogContext.appColors;
        final typography = dialogContext.appTypography;
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'workers.edit_worker.submitting_title'.tr(),
                    style: typography.title2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) => _submittingDialogVisible = false);
  }

  void _dismissSubmittingDialog() {
    if (!_submittingDialogVisible) return;
    _submittingDialogVisible = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showSuccessPopover(WorkerEntity? updatedWorker) {
    final colors = context.appColors;
    final spec = context.appDialogTheme.spec;
    final iconSize = responsiveDimension(60);

    showAppPopover<void>(
      context: context,
      title: 'workers.edit_worker.success_title'.tr(),
      description: 'workers.edit_worker.success_description'.tr(),
      imageLayout: AppDialogImageLayout.iconSmall,
      image: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.successContainer,
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          width: spec.featureIconOuterSize,
          height: spec.featureIconOuterSize,
          child: Center(
            child: AppSvgPicture.asset(
              AppSvgs.successCheck,
              width: iconSize,
              height: iconSize,
            ),
          ),
        ),
      ),
      actions: AppPopoverActions.single,
      primaryLabel: 'workers.edit_worker.success_okay'.tr(),
      barrierDismissible: false,
    ).then((_) {
      if (mounted) context.pop(updatedWorker);
    });
  }

  void _showErrorSnackbar(Failure failure) {
    final message = failure.message.trim();
    final caption = message.isEmpty
        ? 'workers.add_worker.error_invitation_failed'.tr()
        : message.contains(' ')
        ? message
        : message.tr();

    showAppSnackbar(
      context: context,
      title: 'workers.add_worker.error_invitation_failed'.tr(),
      caption: caption,
      color: AppSnackbarColor.error,
    );
  }
}
