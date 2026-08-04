import 'dart:async';

import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:otp/otp.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Saved contact values returned from [showEditContactInformationBottomSheet].
@immutable
class ContactInformationResult {
  const ContactInformationResult({
    required this.phone,
    required this.email,
  });

  final String phone;
  final String email;
}

/// Shows the edit contact information bottom sheet — Figma `3809:18010`.
///
/// Returns updated [ContactInformationResult] when the user taps Save, or
/// `null` if dismissed without saving. When the email is changed, Save opens
/// the shared OTP flow (`OtpFlow.start`) before the new value is returned —
/// this is the reference integration of `sheet_navigation` + `otp`: this
/// sheet morphs to fullscreen while the OTP sheet is presented on top of it.
///
/// **Known limitation:** there is no backend endpoint yet for confirming an
/// organization email change, so [_OrganizationEmailOtpVerifier] mocks the
/// request/verify round-trip (matching the pattern used by the `invitation`
/// package). Swap it for a real `OtpVerifier` once the endpoint exists — no
/// other code here needs to change.
Future<ContactInformationResult?> showEditContactInformationBottomSheet({
  required BuildContext context,
  String? initialPhone,
  String? initialEmail,
}) {
  return SheetNavigator.push<ContactInformationResult>(
    context,
    _EditContactInformationSheetBody(
      initialPhone: initialPhone,
      initialEmail: initialEmail,
    ),
    settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
  );
}

/// Mocks verifying a new organization email until the real endpoint exists.
class _OrganizationEmailOtpVerifier implements OtpVerifier<void> {
  const _OrganizationEmailOtpVerifier();

  @override
  TaskEither<Failure, OtpDelivery> requestCode() {
    return TaskEither<Failure, OtpDelivery>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return right(const OtpDelivery());
    });
  }

  @override
  TaskEither<Failure, void> verifyCode(String code) {
    return TaskEither<Failure, void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return right(null);
    });
  }
}

class _EditContactInformationSheetBody extends StatefulWidget {
  const _EditContactInformationSheetBody({
    this.initialPhone,
    this.initialEmail,
  });

  final String? initialPhone;
  final String? initialEmail;

  @override
  State<_EditContactInformationSheetBody> createState() =>
      _EditContactInformationSheetBodyState();
}

class _EditContactInformationSheetBodyState
    extends State<_EditContactInformationSheetBody> {
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late bool _phoneEditing;
  late bool _emailEditing;

  @override
  void initState() {
    super.initState();
    _phoneEditing = false;
    _emailEditing = false;
    _phoneController = TextEditingController(
      text: UaePhoneValidator.toNationalInput(widget.initialPhone),
    );
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _phoneController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _phoneController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _emailController
      ..removeListener(_onFieldChanged)
      ..dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  bool get _hasPhone => _phoneController.text.trim().isNotEmpty;

  bool get _hasEmail => _emailController.text.trim().isNotEmpty;

  bool get _canSave =>
      _hasPhone &&
      _hasEmail &&
      UaePhoneValidator.isValid(_phoneController.text) &&
      EmailValidator.isValid(_emailController.text);

  bool _verifying = false;

  Future<void> _submit() async {
    if (!_canSave || _verifying) return;
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (email != (widget.initialEmail ?? '')) {
      setState(() => _verifying = true);
      final result = await OtpFlow.start<void>(
        context,
        OtpFlowConfig<void>.email(
          destination: email,
          purpose: OtpPurpose.changeEmail,
          verifier: const _OrganizationEmailOtpVerifier(),
        ),
      );
      if (!mounted) return;
      setState(() => _verifying = false);
      if (!result.isVerified) return;
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(ContactInformationResult(phone: phone, email: email));
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
          _Header(
            colors: context.appColors,
            typography: context.appTypography,
          ),
          SizedBox(height: AppSpacing.lg),
          _buildPhoneField(),
          SizedBox(height: AppSpacing.lg),
          _buildEmailField(),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'settings.save_button'.tr(),
            isLoading: _verifying,
            onPressed: _canSave && !_verifying
                ? () => unawaited(_submit())
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    final label = 'settings.phone_number'.tr();
    final hint = 'settings.phone_number'.tr();

    if (_phoneEditing) {
      return AppPhoneField(
        label: label,
        hint: hint,
        controller: _phoneController,
        isRequired: true,
      );
    }

    if (_hasPhone) {
      return AppPhoneField(
        label: label,
        hint: hint,
        controller: _phoneController,
        readOnly: true,
        showVerifiedBadge: true,
        trailing: AppFieldTextLinkTrailing(
          label: 'settings.change'.tr(),
          onTap: () => setState(() => _phoneEditing = true),
        ),
      );
    }

    return AppPhoneField(
      label: label,
      hint: hint,
      controller: _phoneController,
      isRequired: true,
      readOnly: true,
      trailing: AppFieldOutlinePillTrailing(
        label: 'settings.add'.tr(),
        onTap: () => setState(() => _phoneEditing = true),
      ),
    );
  }

  Widget _buildEmailField() {
    final label = 'settings.email_address'.tr();
    final hint = 'settings.email_address'.tr();

    if (_emailEditing) {
      return AppTextField(
        label: label,
        hint: hint,
        controller: _emailController,
        isRequired: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
      );
    }

    if (_hasEmail) {
      return AppTextField(
        label: label,
        hint: hint,
        controller: _emailController,
        readOnly: true,
        showVerifiedBadge: true,
        trailing: AppFieldTextLinkTrailing(
          label: 'settings.change'.tr(),
          onTap: () => setState(() => _emailEditing = true),
        ),
      );
    }

    return AppTextField(
      label: label,
      hint: hint,
      controller: _emailController,
      isRequired: true,
      readOnly: true,
      trailing: AppFieldOutlinePillTrailing(
        label: 'settings.add'.tr(),
        onTap: () => setState(() => _emailEditing = true),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colors, required this.typography});

  final AppColors colors;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgPicture.asset(
          AppSvgs.phoneOutcome,
          width: AppDimension.iconMenu,
          height: AppDimension.iconMenu,
          colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          'settings.section_contact'.tr(),
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
