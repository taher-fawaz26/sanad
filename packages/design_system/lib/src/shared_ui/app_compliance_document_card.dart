import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Status variants for [AppComplianceDocumentCard].
enum ComplianceDocumentStatus {
  verified,
  expiring,
  expired,
  underReview,
  rejected,
}

/// Figma `Compliance Document Card` (`3821:19211`) — all five variants.
///
/// Displays a compliance document's title, status, license number, and expiry
/// information. State-dependent elements (badge, alert box, CTA button) are
/// rendered automatically based on [status].
class AppComplianceDocumentCard extends StatelessWidget {
  const AppComplianceDocumentCard({
    super.key,
    required this.documentTitle,
    required this.status,
    this.companyName,
    this.licenseNumber,
    this.expiryDate,
    this.countdownText,
    this.alertMessage,
    this.onUpdateDocument,
  });

  /// Document display name, e.g. "Trade License" or "Emirates ID".
  final String documentTitle;
  final ComplianceDocumentStatus status;

  /// Optional — renders a "Company Name" row when non-null.
  final String? companyName;

  /// e.g. "TL-2024-123456".
  final String? licenseNumber;

  /// The expiry date string, e.g. "15 May 2026".
  final String? expiryDate;

  /// Only used when [status] is [ComplianceDocumentStatus.expiring],
  /// e.g. "In 30 days".
  final String? countdownText;

  /// Alert box body text. Falls back to a sensible default when null.
  final String? alertMessage;

  /// Tapped when the "Update Document" CTA is shown and pressed.
  final VoidCallback? onUpdateDocument;

  bool get _showAlert => status != ComplianceDocumentStatus.verified;
  bool get _showCta =>
      status == ComplianceDocumentStatus.expiring ||
      status == ComplianceDocumentStatus.expired ||
      status == ComplianceDocumentStatus.rejected;

  String get _resolvedAlertMessage {
    if (alertMessage != null) return alertMessage!;
    return switch (status) {
      ComplianceDocumentStatus.expiring =>
        'Your document is about to expire. Please renew it to avoid penalties and business suspension.',
      ComplianceDocumentStatus.expired =>
        'Your document has expired. You may not conduct business until renewed.',
      ComplianceDocumentStatus.underReview =>
        'Your renewal is under review. We will update you once processing is complete.',
      ComplianceDocumentStatus.rejected =>
        'Your renewal has been rejected. Please review the comments and resubmit your documents.',
      ComplianceDocumentStatus.verified => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderRow(
            title: documentTitle,
            status: status,
            typography: typography,
          ),
          SizedBox(height: AppSpacing.md),
          const AppDivider(),
          SizedBox(height: AppSpacing.md),
          if (companyName != null) ...[
            _LabelValueRow(
              label: 'Company Name',
              value: companyName!,
              labelColor: colors.textSecondary,
              valueColor: colors.textPrimary,
              valueWeight: FontWeight.w600,
              typography: typography,
            ),
            SizedBox(height: AppSpacing.md),
          ],
          if (licenseNumber != null) ...[
            _LabelValueRow(
              label: 'License No.',
              value: licenseNumber!,
              labelColor: colors.gray400,
              valueColor: colors.textMuted,
              valueWeight: FontWeight.w600,
              typography: typography,
            ),
            SizedBox(height: AppSpacing.md),
          ],
          _ExpiryRow(
            status: status,
            expiryDate: expiryDate,
            countdownText: countdownText,
            typography: typography,
          ),
          if (_showAlert) ...[
            SizedBox(height: AppSpacing.md),
            const AppDivider(),
            SizedBox(height: AppSpacing.md),
            AppAlert(
              message: _resolvedAlertMessage,
              type: _alertTypeFor(status),
            ),
          ],
          if (_showCta) ...[
            SizedBox(height: AppSpacing.md),
            AppButtonPresets.primary(
              label: 'Update Document',
              onPressed: onUpdateDocument,
              icon: AppSvgPicture.asset(
                AppSvgs.cloudUpload,
                width: AppDimension.iconMenu,
                height: AppDimension.iconMenu,
              ),
              iconPosition: AppButtonIconPosition.left,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.title,
    required this.status,
    required this.typography,
  });

  final String title;
  final ComplianceDocumentStatus status;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: typography.regularNone.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 20 / 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        if (status == ComplianceDocumentStatus.verified)
          const AppVerifiedPill()
        else
          AppStatusBadge(
            label: _statusBadgeLabel(status),
            type: _statusBadgeType(status),
            outlined: true,
            size: AppStatusBadgeSize.compact,
          ),
      ],
    );
  }
}

AppStatusBadgeType _statusBadgeType(ComplianceDocumentStatus status) =>
    switch (status) {
      ComplianceDocumentStatus.expiring => AppStatusBadgeType.warning,
      ComplianceDocumentStatus.expired => AppStatusBadgeType.alert,
      ComplianceDocumentStatus.underReview => AppStatusBadgeType.info,
      ComplianceDocumentStatus.rejected => AppStatusBadgeType.alert,
      ComplianceDocumentStatus.verified => AppStatusBadgeType.success,
    };

String _statusBadgeLabel(ComplianceDocumentStatus status) => switch (status) {
  ComplianceDocumentStatus.expiring => 'Expiring Soon',
  ComplianceDocumentStatus.expired => 'Expired',
  ComplianceDocumentStatus.underReview => 'Under Review',
  ComplianceDocumentStatus.rejected => 'Rejected',
  ComplianceDocumentStatus.verified => '',
};

AppAlertType _alertTypeFor(ComplianceDocumentStatus status) => switch (status) {
  ComplianceDocumentStatus.expiring => AppAlertType.warning,
  ComplianceDocumentStatus.expired => AppAlertType.error,
  ComplianceDocumentStatus.underReview => AppAlertType.info,
  ComplianceDocumentStatus.rejected => AppAlertType.rejected,
  ComplianceDocumentStatus.verified => AppAlertType.warning,
};

// ── Rows ────────────────────────────────────────────────────────────────────

class _LabelValueRow extends StatelessWidget {
  const _LabelValueRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    required this.valueWeight,
    required this.typography,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final FontWeight valueWeight;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    final style = typography.smallNormal.copyWith(fontSize: 14);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: style.copyWith(color: labelColor, fontWeight: FontWeight.w400),
        ),
        Text(
          value,
          style: style.copyWith(color: valueColor, fontWeight: valueWeight),
        ),
      ],
    );
  }
}

class _ExpiryRow extends StatelessWidget {
  const _ExpiryRow({
    required this.status,
    required this.typography,
    this.expiryDate,
    this.countdownText,
  });

  final ComplianceDocumentStatus status;
  final AppTypography typography;
  final String? expiryDate;
  final String? countdownText;

  String get _label => switch (status) {
    ComplianceDocumentStatus.underReview => 'Under review since',
    ComplianceDocumentStatus.rejected => 'Rejected on',
    _ => 'Expiry Date',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final labelStyle = typography.smallNormal.copyWith(
      fontSize: 14,
      color: colors.gray400,
      fontWeight: FontWeight.w400,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_label, style: labelStyle),
        _buildValue(colors),
      ],
    );
  }

  Widget _buildValue(AppColors colors) {
    final date = expiryDate;

    return switch (status) {
      ComplianceDocumentStatus.verified => Text(
        date ?? '',
        style: typography.smallNormal.copyWith(
          fontSize: 14,
          color: colors.palettes.red.shade500,
          fontWeight: FontWeight.w600,
        ),
      ),
      ComplianceDocumentStatus.expiring => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (countdownText != null) ...[
            Text(
              countdownText!,
              style: typography.smallNormal.copyWith(
                fontSize: 12,
                color: colors.onWarningContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: AppSpacing.lg),
          ],
          if (date != null)
            Text(
              date,
              style: typography.smallNormal.copyWith(
                fontSize: 14,
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      ComplianceDocumentStatus.expired => Text(
        date != null ? 'Expired on $date' : '',
        style: typography.smallNormal.copyWith(
          fontSize: 12,
          color: colors.palettes.red.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      ComplianceDocumentStatus.underReview ||
      ComplianceDocumentStatus.rejected => Text(
        date ?? '',
        style: typography.smallNormal.copyWith(
          fontSize: 12,
          color: colors.onInfoContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    };
  }
}
