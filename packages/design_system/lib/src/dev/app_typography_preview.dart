import 'package:design_system/src/components/app_divider.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma typography spec page (`177:2763`).
///
/// Dev-only. Not exported from any barrel — for internal showcase/QA use
/// only, imported via its deep `package:design_system/src/dev/...` path.
class AppTypographyPreview extends StatelessWidget {
  const AppTypographyPreview({super.key});

  static const _shortSample = 'The quick brown fox';
  static const _longSample = 'The quick brown fox jumps over the lazy dog';
  static const _aliceSample = 'Alice’s Adventures in Wonderland';
  static const _aliceBody =
      'Alice was beginning to get very tired of sitting by her sister '
      'on the bank, and of having nothing to do:';

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ColumnHeader(colors: colors, typography: typography),
        SizedBox(height: AppSpacing.xl),
        _TitleSpecRow(
          label: 'Title 1',
          metrics: '48pt / 56pt',
          style: typography.title1,
          sample: _shortSample,
        ),
        SizedBox(height: AppSpacing.xxxl),
        _TitleSpecRow(
          label: 'Title 2',
          metrics: '32pt / 36pt',
          style: typography.title2,
          sample: _longSample,
        ),
        SizedBox(height: AppSpacing.xxxl),
        _TitleSpecRow(
          label: 'Title 3',
          metrics: '24pt / 32pt',
          style: typography.title3,
          sample: _longSample,
        ),
        SizedBox(height: AppSpacing.xxxl),
        const AppDivider(),
        SizedBox(height: AppSpacing.xxxl),
        _SizeSection(
          title: 'Large',
          groups: [
            _LineHeightGroup(
              metrics: '18pt / 18pt',
              variant: 'None',
              baseStyle: typography.largeNone,
              shortSample: _shortSample,
            ),
            _LineHeightGroup(
              metrics: '18pt / 20pt',
              variant: 'Tight',
              baseStyle: typography.largeTight,
              shortSample: _longSample,
            ),
            _LineHeightGroup(
              metrics: '18pt / 24pt',
              variant: 'Normal',
              baseStyle: typography.largeNormal,
              shortSample: _longSample,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xxxl),
        const AppDivider(),
        SizedBox(height: AppSpacing.xxxl),
        _SizeSection(
          title: 'Regular',
          groups: [
            _LineHeightGroup(
              metrics: '16pt / 16pt',
              variant: 'None',
              baseStyle: typography.regularNone,
              shortSample: _shortSample,
            ),
            _LineHeightGroup(
              metrics: '16pt / 20pt',
              variant: 'Tight',
              baseStyle: typography.regularTight,
              shortSample: _aliceSample,
            ),
            _LineHeightGroup(
              metrics: '16pt / 24pt',
              variant: 'Normal',
              baseStyle: typography.regularNormal,
              shortSample: _aliceSample,
              bodySample: _aliceBody,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xxxl),
        const AppDivider(),
        SizedBox(height: AppSpacing.xxxl),
        _SizeSection(
          title: 'Small',
          groups: [
            _LineHeightGroup(
              metrics: '14pt / 14pt',
              variant: 'None',
              baseStyle: typography.smallNone,
              shortSample: _shortSample,
            ),
            _LineHeightGroup(
              metrics: '14pt / 16pt',
              variant: 'Tight',
              baseStyle: typography.smallTight,
              shortSample: _aliceSample,
            ),
            _LineHeightGroup(
              metrics: '14pt / 20pt',
              variant: 'Normal',
              baseStyle: typography.smallNormal,
              shortSample: _aliceSample,
              bodySample: _aliceBody,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xxxl),
        const AppDivider(),
        SizedBox(height: AppSpacing.xxxl),
        _SizeSection(
          title: 'Tiny',
          groups: [
            _LineHeightGroup(
              metrics: '12pt / 12pt',
              variant: 'None',
              baseStyle: typography.tinyNone,
              shortSample: _shortSample,
            ),
            _LineHeightGroup(
              metrics: '12pt / 14pt',
              variant: 'Tight',
              baseStyle: typography.tinyTight,
              shortSample: _aliceSample,
              bodySample: _aliceBody,
            ),
            _LineHeightGroup(
              metrics: '12pt / 16pt',
              variant: 'Normal',
              baseStyle: typography.tinyNormal,
              shortSample: _aliceSample,
              bodySample: _aliceBody,
            ),
          ],
        ),
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.colors,
    required this.typography,
  });

  final AppColors colors;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    final labelStyle = typography.tinyNormal.copyWith(color: colors.textMuted);

    return Row(
      children: [
        SizedBox(
          width: AppDimension.contentMaxWidth / 3,
          child: Text('Type', style: labelStyle),
        ),
        SizedBox(
          width: AppDimension.contentMaxWidth / 3,
          child: Text('Font Size / Line Height', style: labelStyle),
        ),
        Text('Example', style: labelStyle),
      ],
    );
  }
}

class _TitleSpecRow extends StatelessWidget {
  const _TitleSpecRow({
    required this.label,
    required this.metrics,
    required this.style,
    required this.sample,
  });

  final String label;
  final String metrics;
  final TextStyle style;
  final String sample;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppDimension.contentMaxWidth / 3,
          child: Text(
            label,
            style: typography.regularNormal.copyWith(color: colors.textPrimary),
          ),
        ),
        SizedBox(
          width: AppDimension.contentMaxWidth / 3,
          child: Text(
            metrics,
            style: typography.regularNormal.copyWith(color: colors.textPrimary),
          ),
        ),
        Expanded(
          child: _ExampleCard(
            child: Text(
              sample,
              style: style.copyWith(color: colors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _SizeSection extends StatelessWidget {
  const _SizeSection({
    required this.title,
    required this.groups,
  });

  final String title;
  final List<_LineHeightGroup> groups;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: typography.regularNormal.copyWith(color: colors.textPrimary),
        ),
        SizedBox(height: AppSpacing.xl),
        for (var i = 0; i < groups.length; i++) ...[
          groups[i],
          if (i < groups.length - 1) SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

class _LineHeightGroup extends StatelessWidget {
  const _LineHeightGroup({
    required this.metrics,
    required this.variant,
    required this.baseStyle,
    required this.shortSample,
    this.bodySample,
  });

  final String metrics;
  final String variant;
  final TextStyle baseStyle;
  final String shortSample;
  final String? bodySample;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final mutedStyle = typography.tinyNormal.copyWith(color: colors.textMuted);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: AppDimension.contentMaxWidth / 3),
        SizedBox(
          width: AppDimension.contentMaxWidth / 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metrics,
                style: typography.regularNormal.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              Text(variant, style: mutedStyle),
            ],
          ),
        ),
        Expanded(
          child: _ExampleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WeightSample(
                  style: typography.bold(baseStyle),
                  text: shortSample,
                ),
                SizedBox(height: AppSpacing.lg),
                _WeightSample(
                  style: typography.medium(baseStyle),
                  text: shortSample,
                ),
                SizedBox(height: AppSpacing.lg),
                _WeightSample(
                  style: typography.regular(baseStyle),
                  text: shortSample,
                ),
                if (bodySample != null) ...[
                  SizedBox(height: AppSpacing.lg),
                  _WeightSample(
                    style: typography.regular(baseStyle),
                    text: bodySample!,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _WeightSample(
                    style: typography.regular(baseStyle),
                    text: bodySample!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeightSample extends StatelessWidget {
  const _WeightSample({
    required this.style,
    required this.text,
  });

  final TextStyle style;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Text(
      text,
      style: style.copyWith(color: colors.textPrimary),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.controlFill,
        borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      ),
      child: child,
    );
  }
}
