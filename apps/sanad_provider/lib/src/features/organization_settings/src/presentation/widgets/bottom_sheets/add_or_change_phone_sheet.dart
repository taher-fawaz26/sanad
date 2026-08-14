import 'dart:async';

import 'package:app_assets/app_assets.dart';
import 'package:contact_verification/contact_verification.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Shows the "Enter Phone Number" bottom sheet — Figma `3809:18016`.
///
/// Used for both Add (no [initialPhone]) and Change (prefilled). On
/// Continue, requests + verifies an OTP via the shared `contact_verification`
/// + `otp` packages (purpose `changeBusinessPhone`); returns the new
/// national phone number once verified, or `null` if dismissed.
Future<String?> showAddOrChangePhoneSheet({
  required BuildContext context,
  String? initialPhone,
}) {
  return SheetNavigator.push<String>(
    context,
    _AddOrChangePhoneSheetBody(initialPhone: initialPhone),
  );
}

class _AddOrChangePhoneSheetBody extends StatefulWidget {
  const _AddOrChangePhoneSheetBody({this.initialPhone});

  final String? initialPhone;

  @override
  State<_AddOrChangePhoneSheetBody> createState() =>
      _AddOrChangePhoneSheetBodyState();
}

class _AddOrChangePhoneSheetBodyState
    extends State<_AddOrChangePhoneSheetBody> {
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: UaePhoneValidator.toNationalInput(widget.initialPhone),
    );
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

  bool get _canContinue => UaePhoneValidator.isValid(_controller.text);

  /// Shown once the user has typed something non-empty that fails
  /// validation — mirrors the empty-is-not-yet-an-error convention used by
  /// the other sheets in this feature (e.g. the social profile URL field).
  String? get _phoneErrorText {
    final value = _controller.text;
    if (value.isEmpty || UaePhoneValidator.isValid(value)) return null;
    return 'settings.phone_number_invalid_error'.tr();
  }

  Future<void> _submit() async {
    if (!_canContinue || _submitting) return;
    final phone = UaePhoneValidator.normalize(_controller.text);

    setState(() => _submitting = true);
    final result = await OtpFlow.start<VerificationResult>(
      context,
      OtpFlowConfig<VerificationResult>.phone(
        destination: phone,
        purpose: OtpPurpose.changePhone,
        verifier: ContactVerificationVerifier(
          purpose: VerificationPurpose.changeBusinessPhone,
          target: phone,
          requestVerification: sl<RequestVerificationUseCase>(),
          resendVerification: sl<ResendVerificationUseCase>(),
          verifyContact: sl<VerifyContactUseCase>(),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!result.isVerified) return;

    Navigator.of(context).pop(_controller.text.trim());
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
          _SheetHeader(
            icon: AppSvgs.phoneOutcome,
            title: 'settings.enter_phone_title'.tr(),
          ),
          SizedBox(height: AppSpacing.lg),
          AppPhoneField(
            label: 'settings.phone_number'.tr(),
            hint: 'settings.phone_number'.tr(),
            controller: _controller,
            isRequired: true,
            errorText: _phoneErrorText,
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'common.continue'.tr(),
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
  const _SheetHeader({required this.icon, required this.title});

  final String icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgPicture.asset(
          icon,
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
