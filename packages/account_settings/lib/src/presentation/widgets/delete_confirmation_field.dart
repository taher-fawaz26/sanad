import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The exact, case-sensitive token the user must type to confirm deletion.
///
/// Client-side only — it is never sent to the backend (`startDeletion` has no
/// body). The literal string is intentionally NOT localized so the required
/// input is identical in every locale (matches the Figma design).
const String kDeletionConfirmationToken = 'DELETE';

/// Owner-only confirmation gate: the user must type
/// [kDeletionConfirmationToken] (`DELETE`) exactly before the destructive
/// action is enabled.
///
/// Comparison is a trimmed, case-sensitive exact match — no case-folding and
/// no whitespace normalization beyond a leading/trailing trim. An error is
/// shown only once the user has typed something that does not (yet) match, so
/// the empty initial state is never flagged. RTL-safe: [AppTextField] follows
/// the ambient [Directionality]; the Latin token stays LTR within the field.
class DeleteConfirmationField extends StatefulWidget {
  const DeleteConfirmationField({
    required this.onConfirmedChanged,
    super.key,
  });

  final ValueChanged<bool> onConfirmedChanged;

  @override
  State<DeleteConfirmationField> createState() =>
      _DeleteConfirmationFieldState();
}

class _DeleteConfirmationFieldState extends State<DeleteConfirmationField> {
  final _controller = TextEditingController();
  bool _lastConfirmed = false;
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final trimmed = value.trim();
    final confirmed = trimmed == kDeletionConfirmationToken;
    // Only surface the mismatch error once the user has typed non-empty text
    // that isn't yet an exact match; clear it when empty or matched.
    final showError = trimmed.isNotEmpty && !confirmed;
    if (confirmed != _lastConfirmed || showError != _showError) {
      setState(() {
        _showError = showError;
      });
      if (confirmed != _lastConfirmed) {
        _lastConfirmed = confirmed;
        widget.onConfirmedChanged(confirmed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: 'account_deletion.type_delete_label'.tr(),
      hint: kDeletionConfirmationToken,
      errorText: _showError ? 'account_deletion.type_delete_error'.tr() : null,
      onChanged: _handleChanged,
    );
  }
}
