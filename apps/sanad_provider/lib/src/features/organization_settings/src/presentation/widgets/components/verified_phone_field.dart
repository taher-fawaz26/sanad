import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Reusable view-mode phone field — Figma "not added" (`+ Add` pill) and
/// "added" (verified badge + value + `Change` link) states.
///
/// Built on [AppPhoneField] in read-only mode so it inherits the exact field
/// chrome, RTL behavior, and trailing actions used everywhere else in the
/// design system. Intended for reuse by any future feature that shows a
/// verifiable organization/user phone number.
class VerifiedPhoneField extends StatefulWidget {
  const VerifiedPhoneField({
    super.key,
    this.phone,
    this.verified = false,
    this.onAdd,
    this.onChange,
  });

  final String? phone;
  final bool verified;
  final VoidCallback? onAdd;
  final VoidCallback? onChange;

  @override
  State<VerifiedPhoneField> createState() => _VerifiedPhoneFieldState();
}

class _VerifiedPhoneFieldState extends State<VerifiedPhoneField> {
  late final TextEditingController _controller;

  bool get _isAdded => widget.phone != null && widget.phone!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: UaePhoneValidator.toNationalInput(widget.phone),
    );
  }

  @override
  void didUpdateWidget(VerifiedPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phone != widget.phone) {
      _controller.text = UaePhoneValidator.toNationalInput(widget.phone);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = 'settings.phone_number'.tr();

    return AppPhoneField(
      label: label,
      hint: label,
      controller: _controller,
      readOnly: true,
      showVerifiedBadge: _isAdded && widget.verified,
      trailing: _isAdded
          ? AppFieldTextLinkTrailing(
              label: 'common.change'.tr(),
              onTap: widget.onChange,
            )
          : AppFieldOutlinePillTrailing(
              label: 'common.add'.tr(),
              onTap: widget.onAdd,
            ),
    );
  }
}
