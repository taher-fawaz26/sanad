import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';
import 'package:sanad_provider/src/features/home/src/presentation/bloc/provider_statistics/provider_statistics_bloc.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_statistics_grid.dart';
import 'package:shared_ui/shared_ui.dart';

final List<ProviderStatisticEntity> _skeletonStatistics = List.generate(
  4,
  (index) => ProviderStatisticEntity(
    key: 'skeleton_$index',
    name: 'Loading',
    value: 0,
  ),
);

/// The provider dashboard home page — `GET service-provider/statistics`.
class ProviderHomePage extends StatelessWidget {
  /// Creates a [ProviderHomePage].
  const ProviderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProviderStatisticsBloc>(
      create: (_) => sl<ProviderStatisticsBloc>()
        ..add(const ProviderStatisticsLoaded()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppNavBar(
        title: 'nav.home'.tr(),
        trailingAction: AppNavBarTrailingAction.icon,
        trailing: AppNotificationIcon(onTap: () {}),
      ),
      body: SafeArea(
        child: BlocBuilder<ProviderStatisticsBloc, ProviderStatisticsState>(
          builder: (context, state) {
            if (state.status == RequestStatus.failure) {
              return _StatisticsError(
                failure: state.failure,
                onRetry: () => context.read<ProviderStatisticsBloc>().add(
                  const ProviderStatisticsRefreshed(),
                ),
              );
            }

            final isLoading =
                state.status == RequestStatus.initial ||
                state.status == RequestStatus.loading;
            final statistics = isLoading
                ? _skeletonStatistics
                : state.statistics;

            return AppSkeletonizer(
              enabled: isLoading,
              child: HomeStatisticsGrid(statistics: statistics),
            );
          },
        ),
      ),
    );
  }
}

class _StatisticsError extends StatelessWidget {
  const _StatisticsError({required this.onRetry, this.failure});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final display = failureErrorDisplay(failure);
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: AppErrorState(
        style: display.isConnectivity
            ? AppErrorStateStyle.network
            : AppErrorStateStyle.generic,
        title: display.title,
        description: display.description,
        retryLabel: failureRetryLabel(),
        onRetry: display.isRetryable ? onRetry : null,
      ),
    );
  }
}
