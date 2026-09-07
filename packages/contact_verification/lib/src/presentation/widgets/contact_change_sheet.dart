import 'dart:async';

import 'package:contact_verification/src/domain/entities/verification_purpose.dart';
import 'package:contact_verification/src/domain/entities/verification_result.dart';
import 'package:contact_verification/src/domain/usecases/get_resend_info_usecase.dart';
import 'package:contact_verification/src/domain/usecases/request_verification_usecase.dart';
import 'package:contact_verification/src/domain/usecases/resend_verification_usecase.dart';
import 'package:contact_verification/src/domain/usecases/verify_contact_usecase.dart';
import 'package:contact_verification/src/domain/verifiers/contact_verification_verifier.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Which contact field is being changed. Selects the input widget, the
/// validator, and the copy — everything else about the four flows is
/// identical.
enum ContactField { email, phone }

/// The one "enter a new email/phone, verify it, return it" sheet.
///
/// Replaces four near-identical copies (business email, business phone, owner
/// email, owner phone) that differed only in validator, `VerificationPurpose`
/// and two copy keys. Returns the accepted value once the OTP is verified, or
/// `null` if the user backed out.
/// [initialValue] is the contact currently on file. It both prefills the field
/// and is the value the input is compared against: Continue stays disabled
/// until the user enters something genuinely different *and* valid, because
/// `/contact-verification/request` answers 409 for a target that is already
/// set. Pass `null` when there is nothing on file yet (the add flow).
Future<String?> showContactChangeSheet({
  required BuildContext context,
  required ContactField field,
  required VerificationPurpose purpose,
  String? initialValue,
}) {
  return SheetNavigator.push<String>(
    context,
    _ContactChangeSheetBody(
      field: field,
      purpose: purpose,
      initialValue: initialValue,
    ),
  );
}

class _ContactChangeSheetBody extends StatefulWidget {
  const _ContactChangeSheetBody({
    required this.field,
    required this.purpose,
    this.initialValue,
  });

  final ContactField field;
  final VerificationPurpose purpose;
  final String? initialValue;

  @override
  State<_ContactChangeSheetBody> createState() =>
      _ContactChangeSheetBodyState();
}

class _ContactChangeSheetBodyState extends State<_ContactChangeSheetBody> {
  late final TextEditingController _controller;
  bool _submitting = false;

  bool get _isEmail => widget.field == ContactField.email;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _isEmail
          ? (widget.initialValue ?? '')
          : UaePhoneValidator.toNationalInput(widget.initialValue),
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

  bool get _isValid => _isEmail
      ? EmailValidator.isValid(_controller.text)
      : UaePhoneValidator.isMobile(_controller.text);

  /// Comparison form, so a change of formatting is not a change of value:
  /// `0501234567`, `501234567` and `+971501234567` are one number, and
  /// `User@X.com` is the address already on file.
  String _canonical(String value) => _isEmail
      ? value.trim().toLowerCase()
      : UaePhoneValidator.normalize(value);

  /// Whether the input differs from the contact currently on file.
  ///
  /// With nothing on file this is the add flow, where any valid value is a
  /// change. Guarding on this is what stops Continue being tappable the moment
  /// the (prefilled) sheet opens, which sent `/request` for an unchanged
  /// target and earned a 409.
  bool get _isChanged {
    final current = widget.initialValue;
    if (current == null || current.trim().isEmpty) return true;
    return _canonical(_controller.text) != _canonical(current);
  }

  bool get _canContinue => _isValid && _isChanged && !_submitting;

  /// Empty is not yet an error — the convention across the settings sheets.
  ///
  /// Neither is an unchanged value: the disabled button is the signal there,
  /// so the user isn't scolded for the text the sheet itself prefilled.
  String? get _errorText {
    if (_controller.text.isEmpty || _isValid) return null;
    return _isEmail
        ? 'settings.email_address_invalid_error'.tr()
        : 'settings.phone_number_invalid_error'.tr();
  }

  Future<void> _submit() async {
    if (!_canContinue) return;

    // The wire value the backend verifies against; for phone this is the
    // normalized E.164 form, which is not what we echo back to the caller.
    final target = _isEmail
        ? _controller.text.trim()
        : UaePhoneValidator.normalize(_controller.text);

    setState(() => _submitting = true);
    final result = await OtpFlow.start<VerificationResult>(
      context,
      _isEmail
          ? OtpFlowConfig<VerificationResult>.email(
              destination: target,
              purpose: OtpPurpose.changeEmail,
              verifier: _verifier(target),
            )
          : OtpFlowConfig<VerificationResult>.phone(
              destination: target,
              purpose: OtpPurpose.changePhone,
              verifier: _verifier(target),
            ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!result.isVerified) return;

    Navigator.of(context).pop(_isEmail ? target : _controller.text.trim());
  }

  ContactVerificationVerifier _verifier(String target) =>
      ContactVerificationVerifier(
        purpose: widget.purpose,
        target: target,
        requestVerification: sl<RequestVerificationUseCase>(),
        resendVerification: sl<ResendVerificationUseCase>(),
        verifyContact: sl<VerifyContactUseCase>(),
        getResendInfo: sl<GetResendInfoUseCase>(),
      );

  @override
  Widget build(BuildContext context) {
    final label = _isEmail
        ? 'settings.email_address'.tr()
        : 'settings.phone_number'.tr();

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsSheetTitle(
            title: _isEmail
                ? 'settings.enter_email_title'.tr()
                : 'settings.enter_phone_title'.tr(),
          ),
          SizedBox(height: AppSpacing.lg),
          if (_isEmail)
            AppTextField(
              label: label,
              hint: label,
              controller: _controller,
              isRequired: true,
              isLtr: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              errorText: _errorText,
            )
          else
            AppPhoneField(
              label: label,
              hint: label,
              controller: _controller,
              isRequired: true,
              errorText: _errorText,
            ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'common.continue'.tr(),
            isLoading: _submitting,
            onPressed: _canContinue ? () => unawaited(_submit()) : null,
          ),
        ],
      ),
    );
  }
}
