import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Owner-only exact business-name confirmation.
///
/// Comparison is a plain trimmed exact match against [businessName] — the
/// same semantics the rest of account settings uses for name fields
/// (`person_name_validator` style: trim, no case-folding, no whitespace
/// normalization beyond a leading/trailing trim). RTL-safe: [AppTextField]
/// already follows ambient [Directionality].
class BusinessNameConfirmField extends StatefulWidget {
  const BusinessNameConfirmField({
    required this.businessName,
    required this.onConfirmedChanged,
    super.key,
  });

  final String businessName;
  final ValueChanged<bool> onConfirmedChanged;

  @override
  State<BusinessNameConfirmField> createState() =>
      _BusinessNameConfirmFieldState();
}

class _BusinessNameConfirmFieldState extends State<BusinessNameConfirmField> {
  final _controller = TextEditingController();
  bool _lastConfirmed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final confirmed = value.trim() == widget.businessName.trim();
    if (confirmed != _lastConfirmed) {
      _lastConfirmed = confirmed;
      widget.onConfirmedChanged(confirmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: 'account_deletion.type_business_name_label'.tr(
        namedArgs: {'businessName': widget.businessName},
      ),
      hint: widget.businessName,
      onChanged: _handleChanged,
    );
  }
}
