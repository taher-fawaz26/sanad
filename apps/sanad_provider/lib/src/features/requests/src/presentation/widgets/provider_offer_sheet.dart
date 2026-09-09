import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/widgets/provider_request_formats.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// A branch the provider may offer from.
class OfferBranchOption {
  /// Creates an option.
  const OfferBranchOption({required this.id, required this.name});

  /// Branch id, sent as `branchId`.
  final String id;

  /// Branch display name.
  final String name;
}

/// What the offer sheet returns.
class ProviderOfferResult {
  /// Creates a result.
  const ProviderOfferResult({
    required this.branchId,
    required this.proposedAt,
    this.note,
  });

  /// The branch that will do the work.
  final String branchId;

  /// The proposed start.
  final DateTime proposedAt;

  /// Optional message to the client.
  final String? note;
}

/// Composes an offer, or a counter to the client's counter.
///
/// Both use the same fields, but a counter is addressed to an existing thread
/// and therefore carries no branch — the branch was fixed when the thread was
/// opened. [branches] being empty puts the sheet in counter mode.
///
/// Pops with a [ProviderOfferResult], or `null` when dismissed.
class ProviderOfferSheet extends StatefulWidget {
  /// Creates the sheet.
  const ProviderOfferSheet({
    required this.title,
    required this.description,
    super.key,
    this.branches = const [],
    this.initial,
  });

  /// Opens the sheet.
  static Future<ProviderOfferResult?> show(
    BuildContext context, {
    required String title,
    required String description,
    List<OfferBranchOption> branches = const [],
    DateTime? initial,
  }) => SheetNavigator.push<ProviderOfferResult>(
    context,
    ProviderOfferSheet(
      title: title,
      description: description,
      branches: branches,
      initial: initial,
    ),
  );

  /// Sheet heading.
  final String title;

  /// One line of context under the heading.
  final String description;

  /// Matched branches to choose from. Empty in counter mode.
  final List<OfferBranchOption> branches;

  /// Seeds the time picker.
  final DateTime? initial;

  @override
  State<ProviderOfferSheet> createState() => _ProviderOfferSheetState();
}

class _ProviderOfferSheetState extends State<ProviderOfferSheet> {
  final TextEditingController _note = TextEditingController();
  DateTime? _proposedAt;
  String? _branchId;
  String? _timeError;
  String? _branchError;

  @override
  void initState() {
    super.initState();
    _proposedAt = widget.initial;
    // With exactly one matched branch there is nothing to choose.
    if (widget.branches.length == 1) _branchId = widget.branches.single.id;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _needsBranch => widget.branches.isNotEmpty;

  Future<void> _pickTime() async {
    final picked = await pickProviderDateTime(context, initial: _proposedAt);
    if (picked == null) return;
    setState(() {
      _proposedAt = picked;
      _timeError = null;
    });
  }

  Future<void> _pickBranch() async {
    final selected = await SheetNavigator.push<String>(
      context,
      SheetScaffold(
        title: 'provider_requests.branch_label'.tr(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final branch in widget.branches)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(branch.name),
                onTap: () => SheetNavigator.pop<String>(context, branch.id),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      _branchId = selected;
      _branchError = null;
    });
  }

  void _submit() {
    // The server answers 400 for a past time and 404 for a branch that never
    // matched. Checking here saves a round trip; it does not replace either.
    final timeError = RequestValidators.futureInstant(_proposedAt);
    final branchMissing = _needsBranch && _branchId == null;
    if (timeError != null || branchMissing) {
      setState(() {
        _timeError = timeError?.tr();
        _branchError = branchMissing
            ? 'provider_requests.branch_placeholder'.tr()
            : null;
      });
      return;
    }
    final note = _note.text.trim();
    SheetNavigator.pop<ProviderOfferResult>(
      context,
      ProviderOfferResult(
        branchId: _branchId ?? '',
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
          if (_needsBranch) ...[
            AppSelectField(
              label: 'provider_requests.branch_label'.tr(),
              value: widget.branches
                  .where((branch) => branch.id == _branchId)
                  .map((branch) => branch.name)
                  .firstOrNull,
              hint: 'provider_requests.branch_placeholder'.tr(),
              errorText: _branchError,
              isRequired: true,
              onTap: _pickBranch,
            ),
            SizedBox(height: AppSpacing.md),
          ],
          AppSelectField(
            label: 'provider_requests.time_label'.tr(),
            value: proposedAt == null
                ? null
                : formatProviderDateTime(context, proposedAt),
            hint: 'client_requests.time_placeholder'.tr(),
            errorText: _timeError,
            isRequired: true,
            onTap: _pickTime,
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _note,
            label: 'provider_requests.note_optional_label'.tr(),
            maxLines: 3,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                RequestFieldLimits.offerNoteMaxLength,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'provider_requests.send'.tr(),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
