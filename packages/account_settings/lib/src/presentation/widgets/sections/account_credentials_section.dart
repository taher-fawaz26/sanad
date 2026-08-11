import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Account credentials section — Figma `3821:18877`.
class AccountCredentialsSection extends StatefulWidget {
  const AccountCredentialsSection({
    super.key,
    this.name,
    this.phone,
    this.email,
    this.emailVerified = false,
    this.onAddPhone,
    this.onChangePhone,
    this.onAddEmail,
    this.onChangeEmail,
  });

  final String? name;
  final String? phone;
  final String? email;
  final bool emailVerified;
  final VoidCallback? onAddPhone;
  final VoidCallback? onChangePhone;
  final VoidCallback? onAddEmail;
  final VoidCallback? onChangeEmail;

  @override
  State<AccountCredentialsSection> createState() =>
      _AccountCredentialsSectionState();
}

class _AccountCredentialsSectionState extends State<AccountCredentialsSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  bool get _phoneAdded => widget.phone != null && widget.phone!.isNotEmpty;
  bool get _emailAdded => widget.email != null && widget.email!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name ?? '');
    _phoneController = TextEditingController(
      text: UaePhoneValidator.toNationalInput(widget.phone),
    );
    _emailController = TextEditingController(text: widget.email ?? '');
  }

  @override
  void didUpdateWidget(AccountCredentialsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _nameController.text = widget.name ?? '';
    }
    if (oldWidget.phone != widget.phone) {
      _phoneController.text = UaePhoneValidator.toNationalInput(widget.phone);
    }
    if (oldWidget.email != widget.email) {
      _emailController.text = widget.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phoneLabel = 'settings.phone_number'.tr();
    final emailLabel = 'settings.email_address'.tr();

    return AppSectionCard(
      title: 'settings.section_account_credentials'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'settings.name'.tr(),
            controller: _nameController,
            readOnly: true,
          ),
          SizedBox(height: AppSpacing.lg),
          AppPhoneField(
            label: phoneLabel,
            hint: phoneLabel,
            controller: _phoneController,
            readOnly: true,
            isRequired: true,
            showVerifiedBadge: _phoneAdded,
            trailing: _phoneAdded
                ? AppFieldTextLinkTrailing(
                    label: 'settings.change'.tr(),
                    onTap: widget.onChangePhone,
                  )
                : AppFieldOutlinePillTrailing(
                    label: 'settings.add'.tr(),
                    onTap: widget.onAddPhone,
                  ),
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: emailLabel,
            hint: emailLabel,
            controller: _emailController,
            isRequired: true,
            showVerifiedBadge: _emailAdded && widget.emailVerified,
            trailing: _emailAdded
                ? AppFieldTextLinkTrailing(
                    label: 'settings.change'.tr(),
                    onTap: widget.onChangeEmail,
                  )
                : AppFieldOutlinePillTrailing(
                    label: 'settings.add'.tr(),
                    onTap: widget.onAddEmail,
                  ),
          ),
        ],
      ),
    );
  }
}
