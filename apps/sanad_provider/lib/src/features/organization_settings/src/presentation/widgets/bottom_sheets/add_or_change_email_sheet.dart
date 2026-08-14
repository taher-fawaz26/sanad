import 'dart:async';

import 'package:app_assets/app_assets.dart';
import 'package:contact_verification/contact_verification.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Shows the "Enter Email" bottom sheet — Figma `3809:18007`.
///
/// Used for both Add (no [initialEmail]) and Change (prefilled). On
/// Continue, requests + verifies an OTP via the shared `contact_verification`
/// + `otp` packages (purpose `changeBusinessEmail`); returns the new email
/// address once verified, or `null` if dismissed.
Future<String?> showAddOrChangeEmailSheet({
  required BuildContext context,
  String? initialEmail,
}) {
  return SheetNavigator.push<String>(
    context,
    _AddOrChangeEmailSheetBody(initialEmail: initialEmail),
  );
}

class _AddOrChangeEmailSheetBody extends StatefulWidget {
  const _AddOrChangeEmailSheetBody({this.initialEmail});

  final String? initialEmail;

  @override
  State<_AddOrChangeEmailSheetBody> createState() =>
      _AddOrChangeEmailSheetBodyState();
}

class _AddOrChangeEmailSheetBodyState
    extends State<_AddOrChangeEmailSheetBody> {
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail ?? '');
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canContinue => EmailValidator.isValid(_controller.text);

  /// Shown once the user has typed something non-empty that fails
  /// validation — mirrors the empty-is-not-yet-an-error convention used by
  /// the other sheets in this feature (e.g. the social profile URL field).
  String? get _emailErrorText {
    final value = _controller.text;
    if (value.isEmpty || EmailValidator.isValid(value)) return null;
    return 'settings.email_address_invalid_error'.tr();
  }

  Future<void> _submit() async {
    if (!_canContinue || _submitting) return;
    final email = _controller.text.trim();

    setState(() => _submitting = true);
    final result = await OtpFlow.start<VerificationResult>(
      context,
      OtpFlowConfig<VerificationResult>.email(
        destination: email,
        purpose: OtpPurpose.changeEmail,
        verifier: ContactVerificationVerifier(
          purpose: VerificationPurpose.changeBusinessEmail,
          target: email,
          requestVerification: sl<RequestVerificationUseCase>(),
          resendVerification: sl<ResendVerificationUseCase>(),
          verifyContact: sl<VerifyContactUseCase>(),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!result.isVerified) return;

    Navigator.of(context).pop(email);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(title: 'settings.enter_email_title'.tr()),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'settings.email_address'.tr(),
            hint: 'settings.email_address'.tr(),
            controller: _controller,
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            errorText: _emailErrorText,
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'settings.continue_button'.tr(),
            isLoading: _submitting,
            onPressed: _canContinue && !_submitting
                ? () => unawaited(_submit())
                : null,
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgPicture.asset(
          AppSvgs.mailOut,
          width: AppDimension.iconMenu,
          height: AppDimension.iconMenu,
          colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: typography.title3.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
