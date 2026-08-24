import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_stat_tile.dart';

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

/// Two-column grid of [HomeStatTile]s, one per [statistics] entry.
///
/// Each tile's icon is resolved from the backend-supplied
/// [ProviderStatisticEntity.icon] CSS class string via
/// [BackendIconResolver] — never a hardcoded icon-name mapping.
class HomeStatisticsGrid extends StatelessWidget {
  const HomeStatisticsGrid({required this.statistics, super.key});

  final List<ProviderStatisticEntity> statistics;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final palette = homeStatIconPalette(colors);

    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: responsiveDimension(140),
      ),
      itemCount: statistics.length,
      itemBuilder: (context, index) {
        final statistic = statistics[index];
        final tint = palette[index % palette.length];

        return HomeStatTile(
          icon: FaIcon(
            BackendIconResolver.resolveOrFallback(statistic.icon),
            color: tint.foreground,
            size: 20,
          ),
          iconBackgroundColor: tint.background,
          value: statistic.value.toString(),
          label: statistic.name,
        );
      },
    );
  }
}
