import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  var _submittingDialogVisible = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddWorkerBloc, AddWorkerState>(
      listener: _onBlocStateChanged,
      child: Scaffold(
        backgroundColor: context.appColors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavBar(
                title: 'workers.add_worker.title'.tr(),
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

    context.read<AddWorkerBloc>().add(
      AddWorkerSubmitEvent(
        InviteWorkerParams(
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

  void _onBlocStateChanged(BuildContext context, AddWorkerState state) {
    if (state.isLoading) {
      _showSubmittingDialog();
      return;
    }
    _dismissSubmittingDialog();

    if (state.isSuccess) {
      _showSuccessPopover();
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
                    'workers.add_worker.submitting_title'.tr(),
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

  void _showSuccessPopover() {
    final colors = context.appColors;
    final spec = context.appDialogTheme.spec;
    final iconSize = responsiveDimension(60);

    showAppPopover<void>(
      context: context,
      title: 'workers.add_worker.success_title'.tr(),
      description: 'workers.add_worker.success_description'.tr(),
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
      primaryLabel: 'workers.add_worker.success_okay'.tr(),
      barrierDismissible: false,
    ).then((_) {
      if (mounted) context.pop();
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
