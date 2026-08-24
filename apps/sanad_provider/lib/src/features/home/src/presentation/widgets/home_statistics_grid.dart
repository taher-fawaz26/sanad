import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_stat_tile.dart';
import 'package:sanad_provider/src/features/home/src/utils/home_stat_navigation.dart';

/// Icon-badge background/foreground pairs, cycled per card — matches the
/// palette already used for KPI cards in `organization_settings_page.dart`.
List<({Color background, Color foreground})> homeStatIconPalette(
  AppColors colors,
) => [
  (
    background: colors.palettes.main.shade50,
    foreground: colors.palettes.dark.shade900,
  ),
  (
    background: colors.palettes.yellow.shade50,
    foreground: colors.palettes.yellow.shade500,
  ),
  (
    background: colors.palettes.accent.shade50,
    foreground: colors.palettes.sky.shade900,
  ),
  (
    background: colors.palettes.sky.shade50,
    foreground: colors.palettes.sky.shade700,
  ),
];

/// Two-column grid of [HomeStatTile]s, one per [statistics] entry — Figma
/// `6755:26159`.
///
/// Cards hug their content (they are not forced to a fixed height), matching
/// the Figma metric card, and each row's two tiles share a height via
/// [IntrinsicHeight]. Each tile's icon is resolved from the backend-supplied
/// [ProviderStatisticEntity.icon] CSS class string via [BackendIconResolver]
/// — never a hardcoded icon-name mapping.
class HomeStatisticsGrid extends StatelessWidget {
  const HomeStatisticsGrid({required this.statistics, super.key});

  final List<ProviderStatisticEntity> statistics;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final palette = homeStatIconPalette(colors);

    final tiles = [
      for (var index = 0; index < statistics.length; index++)
        _buildTile(context, statistics[index], palette[index % palette.length]),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final left = tiles[i];
      final right = i + 1 < tiles.length ? tiles[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              SizedBox(width: AppSpacing.md),
              Expanded(child: right ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.md),
          rows[i],
        ],
      ],
    );
  }

  Widget _buildTile(
    BuildContext context,
    ProviderStatisticEntity statistic,
    ({Color background, Color foreground}) tint,
  ) {
    final route = statRouteForKey(statistic.key);
    return HomeStatTile(
      icon: FaIcon(
        BackendIconResolver.resolveOrFallback(statistic.icon),
        color: tint.foreground,
        size: 16,
      ),
      iconBackgroundColor: tint.background,
      value: statistic.value.toString(),
      label: statistic.name,
      onTap: route == null ? null : () => context.push(route),
    );
  }
}
