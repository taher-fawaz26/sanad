import 'package:flutter/material.dart';

/// Organization profile review/completion status — Figma `Badge`
/// (`4253:26246`), `property1` variants.
enum OrganizationProfileStatus {
  /// Required fields still missing.
  incomplete,

  /// Fully completed, awaiting backend review.
  inReview,

  /// Reviewed and live to customers.
  published,
}

/// Dot + label status pill for the organization identity header — Figma
/// `Badge` (`4253:26246`).
///
/// Colors are literal Figma values, not design-system tokens: this exact
/// dot+soft-fill combination doesn't exist as a design_system primitive
/// today (`AppStatusBadge` has no leading dot), so this stays feature-local
/// rather than approximating with a token that doesn't match on inspection.
class OrganizationStatusBadge extends StatelessWidget {
  const OrganizationStatusBadge({required this.status, super.key});

  final OrganizationProfileStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (status) {
      OrganizationProfileStatus.incomplete => (
        const Color(0x1FF23838),
        const Color(0xFFD12424),
        'Incomplete',
      ),
      OrganizationProfileStatus.inReview => (
        const Color(0x1FF5941F),
        const Color(0xFFC77005),
        'In review',
      ),
      OrganizationProfileStatus.published => (
        const Color(0x1F179E59),
        const Color(0xFF0D8547),
        'Published',
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                height: 16 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
