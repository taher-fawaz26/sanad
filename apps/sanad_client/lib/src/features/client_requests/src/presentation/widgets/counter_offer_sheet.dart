import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_date_time_picker.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// What a counter-offer sheet returns.
class CounterOfferResult {
  /// Creates a result.
  const CounterOfferResult({required this.proposedAt, this.note});

  /// The time the client would prefer instead.
  final DateTime proposedAt;

  /// Optional message to the provider.
  final String? note;
}

/// Proposes a different time for a provider's offer.
///
/// Countering supersedes the provider's offer rather than rejecting it, and
/// hands the turn back to them — the copy says so, because the two outcomes
/// look similar from the client's side but are not the same thing.
///
/// Pops with a [CounterOfferResult], or `null` when dismissed.
class CounterOfferSheet extends StatefulWidget {
  /// Creates the sheet.
  const CounterOfferSheet({super.key, this.initial});

  /// Opens the sheet.
  static Future<CounterOfferResult?> show(
    BuildContext context, {
    DateTime? initial,
  }) => SheetNavigator.push<CounterOfferResult>(
    context,
    CounterOfferSheet(initial: initial),
  );

  /// Seeds the time picker, typically with the provider's proposal.
  final DateTime? initial;

  @override
  State<CounterOfferSheet> createState() => _CounterOfferSheetState();
}

class _CounterOfferSheetState extends State<CounterOfferSheet> {
  final TextEditingController _note = TextEditingController();
  DateTime? _proposedAt;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await pickRequestDateTime(context, initial: _proposedAt);
    if (picked == null) return;
    setState(() {
      _proposedAt = picked;
      _error = null;
    });
  }

  void _submit() {
    // The server answers 400 for a past time; checking here keeps the user
    // out of a pointless round trip without replacing the server's authority.
    final error = RequestValidators.futureInstant(_proposedAt);
    if (error != null) {
      setState(() => _error = error.tr());
      return;
    }
    final note = _note.text.trim();
    SheetNavigator.pop<CounterOfferResult>(
      context,
      CounterOfferResult(
        proposedAt: _proposedAt!,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final proposedAt = _proposedAt;

    return SheetScaffold(
      title: 'client_requests.counter_sheet_title'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'client_requests.counter_sheet_description'.tr(),
            style: typography.bodySmall.copyWith(color: colors.slate600),
          ),
          SizedBox(height: AppSpacing.lg),
          AppSelectField(
            label: 'client_requests.time_label'.tr(),
            value: proposedAt == null
                ? null
                : formatRequestDateTime(context, proposedAt),
            hint: 'client_requests.time_placeholder'.tr(),
            errorText: _error,
            isRequired: true,
            onTap: _pickTime,
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _note,
            label: 'client_requests.note_optional_label'.tr(),
            maxLines: 3,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                RequestFieldLimits.offerNoteMaxLength,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'client_requests.send'.tr(),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
