import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Collects the reason a provider cancellation requires, and doubles as the
/// confirmation step for actions that cost something.
///
/// Pops with the trimmed reason, or `null` when dismissed.
class ProviderReasonSheet extends StatefulWidget {
  /// Creates the sheet.
  const ProviderReasonSheet({
    required this.title,
    required this.description,
    required this.confirmLabel,
    super.key,
    this.requiresReason = true,
  });

  /// Opens the sheet and returns the reason, or `null` if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmLabel,
  }) => SheetNavigator.push<String>(
    context,
    ProviderReasonSheet(
      title: title,
      description: description,
      confirmLabel: confirmLabel,
    ),
  );

  /// Opens the sheet as a plain confirmation, with no reason field.
  ///
  /// Used for withdrawing an offer: the server wants no reason, but the action
  /// consumes a re-bid, so it must not happen on a single unguarded tap.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmLabel,
  }) async {
    final result = await SheetNavigator.push<String>(
      context,
      ProviderReasonSheet(
        title: title,
        description: description,
        confirmLabel: confirmLabel,
        requiresReason: false,
      ),
    );
    return result != null;
  }

  /// Sheet heading.
  final String title;

  /// One line explaining the consequence.
  final String description;

  /// Label of the confirming button.
  final String confirmLabel;

  /// Whether a reason must be entered.
  final bool requiresReason;

  @override
  State<ProviderReasonSheet> createState() => _ProviderReasonSheetState();
}

class _ProviderReasonSheetState extends State<ProviderReasonSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.requiresReason) {
      SheetNavigator.pop<String>(context, '');
      return;
    }
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
          if (widget.requiresReason) ...[
            SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _controller,
              label: 'provider_requests.reason_label'.tr(),
              errorText: _error,
              maxLines: 4,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  RequestFieldLimits.reasonMaxLength,
                ),
              ],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
          SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.confirmLabel,
            onPressed: _submit,
            intent: AppButtonIntent.destructive,
          ),
        ],
      ),
    );
  }
}
