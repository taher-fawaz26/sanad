import 'dart:async';

import 'package:activity_logs/activity_logs.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';
import 'package:sanad_provider/src/features/home/src/presentation/bloc/provider_statistics/provider_statistics_bloc.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_header.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_quick_actions.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_setup_card.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_statistics_grid.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:shared_ui/shared_ui.dart';

final List<ProviderStatisticEntity> _skeletonStatistics = List.generate(
  4,
  // `name` is skeleton-masked, never read as copy — BoneMock keeps it out of
  // the localized surface entirely (same convention as the recent-activity
  // section) instead of shipping a hardcoded English placeholder.
  (index) => ProviderStatisticEntity(
    key: 'skeleton_$index',
    name: BoneMock.words(2),
    value: 0,
  ),
);

/// The provider dashboard home page — Figma `6755:25921`.
///
/// A composition layer over already-existing features: statistics
/// (`GET service-provider/statistics`), setup completion
/// (`GET service-provider/completion`, reused from Organization Settings),
/// Quick Actions (existing routes), and Recent Activity (reused from
/// `activity_logs`, global latest-5). Each section renders its own
/// loading/error state, so one section failing never blocks the others.
class ProviderHomePage extends StatelessWidget {
  /// Creates a [ProviderHomePage].
  const ProviderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProviderStatisticsBloc>(
          create: (_) =>
              sl<ProviderStatisticsBloc>()
                ..add(const ProviderStatisticsLoaded()),
        ),
        BlocProvider<ProviderCompletionBloc>(
          create: (_) =>
              sl<ProviderCompletionBloc>()
                ..add(const ProviderCompletionLoaded()),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  Future<void> _onRefresh(BuildContext context) async {
    context.read<ProviderStatisticsBloc>().add(
      const ProviderStatisticsRefreshed(),
    );
    context.read<ProviderCompletionBloc>().add(
      const ProviderCompletionRefreshed(),
    );
  }

  /// Complete Setup goes straight to the General Settings editor (profile /
  /// cover / business identity) — not the outer Settings hub — then refreshes
  /// the setup-completion and statistics on return, since either can change.
  Future<void> _onCompleteSetup(BuildContext context) async {
    await context.push<Object?>(OrganizationSettingsRoutes.general);
    if (!context.mounted) return;
    context.read<ProviderCompletionBloc>().add(
      const ProviderCompletionRefreshed(),
    );
    context.read<ProviderStatisticsBloc>().add(
      const ProviderStatisticsRefreshed(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Read here so a locale change (which rebuilds this subtree via
    // `app.dart`) remounts the activity section under a new key and re-fires
    // its `load()` in the new language.
    final languageCode = context.locale.languageCode;

    return BlocListener<TranslateBloc, TranslateState>(
      listenWhen: (previous, current) =>
          previous.languageCode != current.languageCode,
      listener: (context, _) {
        // Backend-localized sections are stale after a language switch — the
        // network layer already sends the new language, so re-fetch. Each
        // bloc's cache is language-keyed, so this fetches new-language data.
        context.read<ProviderStatisticsBloc>().add(
          const ProviderStatisticsRefreshed(),
        );
        context.read<ProviderCompletionBloc>().add(
          const ProviderCompletionRefreshed(),
        );
      },
      child: AppScrollPage(
        backgroundColor: colors.background,
        onRefresh: () => _onRefresh(context),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.xl,
                children: [
                  const HomeHeader(),
                  HomeSetupCard(
                    onCompleteSetup: () => unawaited(_onCompleteSetup(context)),
                  ),
                  BlocBuilder<ProviderStatisticsBloc, ProviderStatisticsState>(
                    builder: (context, state) {
                      if (state.status == RequestStatus.failure) {
                        return _StatisticsError(
                          failure: state.failure,
                          onRetry: () => context
                              .read<ProviderStatisticsBloc>()
                              .add(const ProviderStatisticsRefreshed()),
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
                  const HomeQuickActions(),
                  HomeRecentActivitySection(key: ValueKey(languageCode)),
                ],
              ),
            ),
          ),
        ],
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
    return AppErrorState(
      style: display.isConnectivity
          ? AppErrorStateStyle.network
          : AppErrorStateStyle.generic,
      title: display.title,
      description: display.description,
      retryLabel: failureRetryLabel(),
      onRetry: display.isRetryable ? onRetry : null,
    );
  }
}
