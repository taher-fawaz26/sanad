import 'package:activity_logs/src/domain/entities/activity_action.dart';
import 'package:activity_logs/src/domain/entities/activity_actor.dart';
import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/domain/entities/activity_subject.dart';
import 'package:activity_logs/src/presentation/bloc/worker_activity/worker_activity_cubit.dart';
import 'package:activity_logs/src/presentation/widgets/activity_log_error_state.dart';
import 'package:activity_logs/src/presentation/widgets/activity_timeline.dart';
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
    subject: ActivitySubject(
      type: ActivitySubjectType.unknown,
      id: 'skeleton',
      name: BoneMock.words(2),
    ),
  ),
);

/// Figma `Activity Log List - V2` (`6902:24787`) — a fixed recent-activity
/// slice for one worker, embedded as a card on Worker Details. Deliberately
/// not paginated: the design shows a static slice with no "see all"
/// affordance.
///
/// Self-contained: creates and owns its own [WorkerActivityCubit], so it can
/// be dropped into any screen with just a [workerId] — no route-level
/// bloc wiring required.
class WorkerRecentActivitySection extends StatelessWidget {
  const WorkerRecentActivitySection({required this.workerId, super.key});

  final String workerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WorkerActivityCubit>()
        ..load(actorId: workerId, languageCode: context.locale.languageCode),
      child: _RecentActivityCard(workerId: workerId),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.workerId});

  final String workerId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final dark = colors.palettes.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: dark.shade50,
        borderRadius: BorderRadius.circular(AppDimension.radiusProfileCard),
        border: Border.all(color: dark.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'activity_log.recent_title'.tr(),
            style: typography.regularNormal.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 24 / 16,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          BlocBuilder<WorkerActivityCubit, WorkerActivityState>(
            builder: (context, state) {
              if (state.isLoadingFirstLoad) {
                return AppSkeletonizer(
                  enabled: true,
                  child: ActivityTimeline(entries: _skeletonEntries),
                );
              }
              if (state.status == RequestStatus.failure) {
                return ActivityLogErrorState(
                  failure: state.failure,
                  onRetry: () => context.read<WorkerActivityCubit>().load(
                    actorId: workerId,
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
              return ActivityTimeline(entries: state.items);
            },
          ),
        ],
      ),
    );
  }
}
