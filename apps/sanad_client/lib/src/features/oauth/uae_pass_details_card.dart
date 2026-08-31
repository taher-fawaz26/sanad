import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Per-row state for a [UaePassDetailRowData] — Figma's "Component 8" trailing
/// indicator (`7042:28730` / `7042:28727` / `7042:28723`): a green checkmark
/// once a field has arrived, a spinning arc while still waiting on it.
enum UaePassDetailRowStatus {
  /// Field not yet received — shows a spinning loading arc.
  loading,

  /// Field received — shows [AppVerifiedBadge].
  completed,
}

/// One row's content for [UaePassDetailsCard].
class UaePassDetailRowData extends Equatable {
  /// Creates a [UaePassDetailRowData].
  const UaePassDetailRowData({
    required this.iconAsset,
    required this.label,
    required this.value,
    required this.status,
  });

  /// Leading icon (`AppSvgs.*`), tinted via the shared row icon container.
  final String iconAsset;

  /// Row label (e.g. "Full name").
  final String label;

  /// Row value (e.g. "Mohamed Shahat").
  final String value;

  /// Whether this field has arrived yet.
  final UaePassDetailRowStatus status;

  @override
  List<Object?> get props => [iconAsset, label, value, status];
}

/// Shared UAE PASS details card (Figma `7027:25502` / `7043:28772`) — used by
/// both "We collect data from UAE PASS" (rows mid-collection) and "You're all
/// set!" (rows all [UaePassDetailRowStatus.completed]) so the card/row markup
/// is not duplicated between the two screens.
class UaePassDetailsCard extends StatelessWidget {
  /// Creates a [UaePassDetailsCard].
  const UaePassDetailsCard({
    required this.title,
    required this.rows,
    super.key,
  });

  /// Card header (e.g. "Collecting Your Details..." or "Your Details").
  final String title;

  /// Rows to render, in order.
  final List<UaePassDetailRowData> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsiveDimension(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: colors.palettes.sky.shade50,
        borderRadius: AppRadius.circularLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: responsiveDimension(AppSpacing.sm),
            ),
            child: Text(
              title,
              style: typography.smallNormal.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: responsiveDimension(AppSpacing.md),
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(
                responsiveDimension(AppDimension.radiusMd),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  _DetailRow(data: rows[i]),
                  if (i < rows.length - 1) const AppDivider(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.data});

  final UaePassDetailRowData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: responsiveDimension(AppSpacing.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _RowIcon(assetPath: data.iconAsset),
                // Figma `7019:28137` gap — not on the [AppSpacing] scale.
                SizedBox(width: responsiveDimension(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.label,
                        style: typography.smallNormal.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: responsiveDimension(AppSpacing.xs)),
                      Text(
                        data.value,
                        textDirection: TextDirection.ltr,
                        style: typography.tinyNormal.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsiveDimension(AppSpacing.sm)),
          switch (data.status) {
            UaePassDetailRowStatus.completed => const AppVerifiedBadge(),
            UaePassDetailRowStatus.loading => const _LoadingArcIcon(),
          },
        ],
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final sky = context.appColors.palettes.sky;

    return Container(
      width: responsiveDimension(40),
      height: responsiveDimension(40),
      decoration: BoxDecoration(color: sky.shade100, shape: BoxShape.circle),
      child: Center(
        child: AppSvgPicture.asset(
          assetPath,
          width: responsiveDimension(24),
          height: responsiveDimension(24),
          colorFilter: ColorFilter.mode(sky.shade700, BlendMode.srcIn),
        ),
      ),
    );
  }
}

/// Per-row loading indicator (`AppSvgs.uaePassLoadingArc`, Figma's "Half
/// Circle" glyph) — rendered as a static glyph, not spun: Figma defines no
/// rotation keyframes for it, and a repeating animation here would leave a
/// pending timer behind every `pumpAndSettle()` call on this card while any
/// row is still loading (see `testing.md`'s "no `pumpAndSettle()` under a
/// repeating animation" rule).
class _LoadingArcIcon extends StatelessWidget {
  const _LoadingArcIcon();

  @override
  Widget build(BuildContext context) {
    return AppSvgPicture.asset(
      AppSvgs.uaePassLoadingArc,
      width: responsiveDimension(AppDimension.iconCompact),
      height: responsiveDimension(AppDimension.iconCompact),
    );
  }
}
