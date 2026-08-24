import 'package:activity_logs/src/domain/entities/activity_action.dart';
import 'package:activity_logs/src/domain/entities/activity_actor.dart';
import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/presentation/bloc/recent_activity/recent_activity_cubit.dart';
import 'package:activity_logs/src/presentation/utils/activity_log_time_formatter.dart';
import 'package:activity_logs/src/presentation/widgets/activity_log_error_state.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_ui/shared_ui.dart';

final List<ActivityLogEntry> _skeletonEntries = List.generate(
  3,
  (_) => ActivityLogEntry(
    action: ActivityAction.unknown,
    name: BoneMock.words(3),
    timestamp: DateTime.now(),
    actor: const ActivityActor(name: '', type: ActivityActorType.unknown),
  ),
);

/// Home dashboard "Recent Activity" preview — Figma `6755:26034`.
///
/// A global (unfiltered) latest-5 slice — no actor filter, no pagination, no
/// "see all". Self-contained: creates and owns its own [RecentActivityCubit],
/// so it drops into the Home page with no route-level bloc wiring. A failure
/// here renders an inline compact error and never blocks the rest of Home.
class HomeRecentActivitySection extends StatelessWidget {
  const HomeRecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<RecentActivityCubit>()
            ..load(languageCode: context.locale.languageCode),
      child: const _RecentActivityCard(),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'activity_log.recent_title'.tr(),
            style: typography.largeNormal.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          BlocBuilder<RecentActivityCubit, RecentActivityState>(
            builder: (context, state) {
              if (state.isLoadingFirstLoad) {
                return AppSkeletonizer(
                  enabled: true,
                  child: _ActivityList(entries: _skeletonEntries),
                );
              }
              if (state.status == RequestStatus.failure) {
                return ActivityLogErrorState(
                  failure: state.failure,
                  onRetry: () => context.read<RecentActivityCubit>().load(
                    languageCode: context.locale.languageCode,
                    forceRefresh: true,
                  ),
                );
              }
              if (state.isEmpty) {
                return Text(
                  'activity_log.empty'.tr(),
                  style: typography.smallNormal.copyWith(
                    color: colors.textMuted,
                  ),
                );
              }
              return _ActivityList(entries: state.items);
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.entries});

  final List<ActivityLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.md),
          _HomeActivityRow(entry: entries[i]),
        ],
      ],
    );
  }
}

/// One Home activity row — Figma `6755:26037`: an actor-initials avatar, a
/// line that emphasizes the actor name in bold followed by the localized
/// action text, and a relative timestamp beneath it.
///
/// The backend action text (`entry.name`) is already localized. When it
/// leads with the actor's name, only that prefix is bolded; otherwise the
/// actor name is prepended in bold — no fragile mid-string splitting, and
/// no client-side translation of backend-owned text.
class _HomeActivityRow extends StatelessWidget {
  const _HomeActivityRow({required this.entry});

  final ActivityLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final locale = context.locale.toString();
    final initials = initialsOf(entry.actor.name) ?? '?';

    final baseStyle = typography.smallNormal.copyWith(
      color: colors.palettes.dark.shade600,
    );
    final actorStyle = baseStyle.copyWith(
      color: colors.textPrimary,
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Container(
          width: responsiveDimension(32),
          height: responsiveDimension(32),
          decoration: BoxDecoration(
            color: colors.successContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: typography.smallNormal.copyWith(
              color: colors.palettes.main.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Text.rich(
                _describe(baseStyle: baseStyle, actorStyle: actorStyle),
              ),
              Text(
                ActivityLogTimeFormatter.format(
                  entry.timestamp,
                  locale: locale,
                ),
                style: typography.tinyNormal.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the "**Actor** action text" span, avoiding duplication when the
  /// localized `entry.name` already begins with the actor's name.
  TextSpan _describe({
    required TextStyle baseStyle,
    required TextStyle actorStyle,
  }) {
    final actor = entry.actor.name.trim();
    final text = entry.name.trim();

    if (actor.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }
    if (text.toLowerCase().startsWith(actor.toLowerCase())) {
      return TextSpan(
        children: [
          TextSpan(text: text.substring(0, actor.length), style: actorStyle),
          TextSpan(text: text.substring(actor.length), style: baseStyle),
        ],
      );
    }
    return TextSpan(
      children: [
        TextSpan(text: actor, style: actorStyle),
        if (text.isNotEmpty) TextSpan(text: ' $text', style: baseStyle),
      ],
    );
  }
}
