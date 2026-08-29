import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Reusable view-mode email field — Figma "not added" (`+ Add` pill) and
/// "added" (verified badge + value + `Change` link) states.
///
/// Built on [AppTextField] in read-only mode so it inherits the exact field
/// chrome, RTL behavior, and trailing actions used everywhere else in the
/// design system. Intended for reuse by any future feature that shows a
/// verifiable organization/user email address.
class VerifiedEmailField extends StatefulWidget {
  const VerifiedEmailField({
    super.key,
    this.email,
    this.verified = false,
    this.onAdd,
    this.onChange,
  });

  final String? email;
  final bool verified;
  final VoidCallback? onAdd;
  final VoidCallback? onChange;

  @override
  State<VerifiedEmailField> createState() => _VerifiedEmailFieldState();
}

class _VerifiedEmailFieldState extends State<VerifiedEmailField> {
  late final TextEditingController _controller;

  bool get _isAdded => widget.email != null && widget.email!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.email ?? '');
  }

  @override
  void didUpdateWidget(VerifiedEmailField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.email != widget.email) {
      _controller.text = widget.email ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = 'settings.email_address'.tr();

    return AppTextField(
      label: label,
      hint: label,
      controller: _controller,
      readOnly: true,
      isLtr: true,
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
