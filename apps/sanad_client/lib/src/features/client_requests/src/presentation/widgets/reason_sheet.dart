import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Collects the reason that cancel and dispute both require.
///
/// The backend enforces 3–1000 characters and shows the text to the other
/// party verbatim, so it is validated here before a round trip.
///
/// Pops with the trimmed reason, or `null` when dismissed without sending —
/// the convention every sheet in this app follows.
class ReasonSheet extends StatefulWidget {
  /// Creates the sheet.
  const ReasonSheet({
    required this.title,
    required this.description,
    required this.confirmLabel,
    super.key,
    this.isDestructive = false,
  });

  /// Opens the sheet and returns the reason, or `null` if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmLabel,
    bool isDestructive = false,
  }) => SheetNavigator.push<String>(
    context,
    ReasonSheet(
      title: title,
      description: description,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    ),
  );

  /// Sheet heading.
  final String title;

  /// One line explaining who will read the reason.
  final String description;

  /// Label of the confirming button.
  final String confirmLabel;

  /// Renders the confirm button as a destructive action.
  final bool isDestructive;

  @override
  State<ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<ReasonSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final error = RequestValidators.reason(_controller.text);
    if (error != null) {
      setState(() => _error = error.tr());
      return;
    }
    SheetNavigator.pop<String>(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return SheetScaffold(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.description,
            style: typography.bodySmall.copyWith(color: colors.slate600),
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _controller,
            label: 'client_requests.reason_label'.tr(),
            hint: 'client_requests.reason_placeholder'.tr(),
            errorText: _error,
            maxLines: 4,
            // Hard-stops at the server's own bound so the user cannot type
            // past it and only learn from a 400.
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                RequestFieldLimits.reasonMaxLength,
              ),
            ],
            // Clear the error as soon as the user starts fixing it, rather
            // than leaving it under the field until the next submit.
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.confirmLabel,
            onPressed: _submit,
            intent: widget.isDestructive
                ? AppButtonIntent.destructive
                : AppButtonIntent.standard,
          ),
        ],
      ),
    );
  }
}
