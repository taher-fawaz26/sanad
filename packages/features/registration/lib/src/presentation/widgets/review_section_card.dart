import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
// Hide intl's TextDirection (re-exported by easy_localization) so the
// dart:ui/material TextDirection with `.rtl` / `.ltr` is used below.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:registration/src/data/models/extraction_result.dart';
import 'package:registration/src/presentation/widgets/captured_image.dart';

/// One document section on the Review Information screen (Emirates ID or Trade
/// Licence). Renders a header with a status badge, a two-column field grid, an
/// optional error banner, and a "Replace Document" action.
class ReviewSectionCard extends StatelessWidget {
  const ReviewSectionCard({
    required this.title,
    required this.issue,
    required this.fields,
    required this.onReplace,
    this.thumbnail,
    super.key,
  });

  final String title;
  final DocumentIssue issue;
  final List<ExtractedField> fields;
  final VoidCallback onReplace;
  final PickedAsset? thumbnail;

  bool get _ok => issue == DocumentIssue.none;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
            _Header(title: title, issue: issue, thumbnail: thumbnail),
            SizedBox(height: responsiveDimension(AppSpacing.lg)),
            _FieldGrid(fields: fields),
            if (!_ok) ...[
              SizedBox(height: responsiveDimension(AppSpacing.lg)),
              _ErrorBanner(issue: issue),
            ],
            SizedBox(height: responsiveDimension(AppSpacing.lg)),
            AppButtonPresets.outline(
              label: 'registration.replace_document'.tr(),
              onPressed: onReplace,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.issue,
    required this.thumbnail,
  });

  final String title;
  final DocumentIssue issue;
  final PickedAsset? thumbnail;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    final (badgeLabel, badgeType) = switch (issue) {
      DocumentIssue.none => (
          'registration.extracted_success'.tr(),
          AppStatusBadgeType.success,
        ),
      DocumentIssue.imageUnclear => (
          'registration.image_unclear'.tr(),
          AppStatusBadgeType.warning,
        ),
      DocumentIssue.expiredLicence => (
          'registration.expired'.tr(),
          AppStatusBadgeType.alert,
        ),
    };

    return Row(
      children: [
        if (thumbnail != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(responsiveDimension(6)),
            child: SizedBox(
              width: responsiveDimension(40),
              height: responsiveDimension(28),
              child: CapturedImage(
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
          label: badgeLabel,
          type: badgeType,
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
      crossAxisAlignment:
          field.rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
  const _ErrorBanner({required this.issue});

  final DocumentIssue issue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    final (title, message) = switch (issue) {
      DocumentIssue.expiredLicence => (
          'registration.expired'.tr(),
          'registration.expired_message'.tr(),
        ),
      _ => (
          'registration.image_unclear'.tr(),
          'registration.image_unclear_message'.tr(),
        ),
    };

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
