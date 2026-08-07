import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:document_flow/src/domain/entities/extracted_field.dart';
import 'package:document_flow/src/presentation/widgets/document_preview.dart';
import 'package:flutter/material.dart';

/// The label/badge/banner copy for one [DocumentIssue] value, resolved by the
/// feature so this widget carries no l10n keys of its own.
class DocumentIssueLabels {
  const DocumentIssueLabels({
    required this.badgeLabel,
    required this.badgeType,
    this.bannerTitle,
    this.bannerMessage,
  });

  final String badgeLabel;
  final AppStatusBadgeType badgeType;
  final String? bannerTitle;
  final String? bannerMessage;
}

/// Resolves the labels to show for a given [DocumentIssue].
typedef IssueLabelResolver = DocumentIssueLabels Function(DocumentIssue issue);

/// One document section on a review screen. Renders a header with a status
/// badge, a two-column field grid, an optional error banner, and a
/// "Replace Document" action.
class ExtractedFieldsView extends StatelessWidget {
  const ExtractedFieldsView({
    required this.title,
    required this.issue,
    required this.fields,
    required this.onReplace,
    required this.replaceLabel,
    required this.resolveIssueLabels,
    this.thumbnail,
    super.key,
  });

  final String title;
  final DocumentIssue issue;
  final List<ExtractedField> fields;
  final VoidCallback onReplace;
  final String replaceLabel;
  final IssueLabelResolver resolveIssueLabels;
  final PickedAsset? thumbnail;

  bool get _ok => issue == DocumentIssue.none;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final issueLabels = resolveIssueLabels(issue);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusProfileCard),
        border: Border.all(color: _ok ? colors.gray100 : colors.error),
      ),
      child: Padding(
        padding: EdgeInsets.all(responsiveDimension(AppSpacing.xl)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(title: title, thumbnail: thumbnail, labels: issueLabels),
            SizedBox(height: responsiveDimension(AppSpacing.lg)),
            _FieldGrid(fields: fields),
            if (!_ok &&
                issueLabels.bannerTitle != null &&
                issueLabels.bannerMessage != null) ...[
              SizedBox(height: responsiveDimension(AppSpacing.lg)),
              _ErrorBanner(
                title: issueLabels.bannerTitle!,
                message: issueLabels.bannerMessage!,
              ),
            ],
            SizedBox(height: responsiveDimension(AppSpacing.lg)),
            AppButtonPresets.outline(label: replaceLabel, onPressed: onReplace),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.thumbnail,
    required this.labels,
  });

  final String title;
  final PickedAsset? thumbnail;
  final DocumentIssueLabels labels;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      children: [
        if (thumbnail != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(responsiveDimension(6)),
            child: SizedBox(
              width: responsiveDimension(40),
              height: responsiveDimension(28),
              child: DocumentPreview(
                asset: thumbnail!,
                fallback: ColoredBox(color: colors.gray100),
              ),
            ),
          ),
          SizedBox(width: responsiveDimension(AppSpacing.sm)),
        ],
        Expanded(
          child: Text(
            title,
            style: typography.smallNormal.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
        ),
        AppStatusBadge(
          label: labels.badgeLabel,
          type: labels.badgeType,
          size: AppStatusBadgeSize.compact,
        ),
      ],
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.fields});

  final List<ExtractedField> fields;

  @override
  Widget build(BuildContext context) {
    final gap = responsiveDimension(AppSpacing.lg);

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final field in fields)
              SizedBox(
                width: field.fullWidth ? constraints.maxWidth : halfWidth,
                child: _Field(field: field),
              ),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.field});

  final ExtractedField field;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final hasValue = field.value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: field.rtl
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: typography.tinyNormal.copyWith(color: colors.textMuted),
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xs)),
        Text(
          hasValue ? field.value : '—',
          textAlign: field.rtl ? TextAlign.right : TextAlign.start,
          textDirection: field.rtl ? TextDirection.rtl : null,
          style: typography.smallNormal.copyWith(
            fontWeight: FontWeight.w600,
            color: hasValue
                ? (field.highlight ? colors.error : colors.textPrimary)
                : colors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.circularMd,
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: EdgeInsets.all(responsiveDimension(AppSpacing.md)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSvgPicture.asset(
              AppSvgs.registrationAlertCancel,
              width: responsiveDimension(18),
              height: responsiveDimension(18),
              colorFilter: ColorFilter.mode(colors.error, BlendMode.srcIn),
            ),
            SizedBox(width: responsiveDimension(AppSpacing.sm)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: typography.smallNormal.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.error,
                    ),
                  ),
                  SizedBox(height: responsiveDimension(AppSpacing.xs)),
                  Text(
                    message,
                    style: typography.tinyNormal.copyWith(color: colors.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
