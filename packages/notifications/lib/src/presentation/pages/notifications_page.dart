import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:notifications/src/domain/entities/app_notification.dart';
import 'package:notifications/src/navigation/notification_navigator.dart';
import 'package:notifications/src/presentation/bloc/notifications/notifications_bloc.dart';
import 'package:notifications/src/presentation/widgets/notification_row.dart';
import 'package:shared_ui/shared_ui.dart';

/// The notification inbox.
///
/// The navigator is supplied by the app, because a client and a provider open
/// the same subject through different screens. Subject *parsing* is shared;
/// only the destination is role-specific.
///
/// It is resolved lazily and may be `null`: the app's navigator needs a live
/// router, which does not exist when the module is constructed. A row still
/// opens (and marks itself read) without one.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    required this.bloc,
    required this.resolveNavigator,
    super.key,
  });

  final NotificationsBloc Function() bloc;
  final NotificationNavigator? Function() resolveNavigator;

  @override
  Widget build(BuildContext context) => BlocProvider<NotificationsBloc>(
    create: (_) => bloc()..add(const NotificationsStarted()),
    child: _NotificationsView(resolveNavigator: resolveNavigator),
  );
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView({required this.resolveNavigator});

  final NotificationNavigator? Function() resolveNavigator;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<NotificationsBloc, NotificationsState>(
              buildWhen: (a, b) => a.unreadCount != b.unreadCount,
              builder: (context, state) => AppNavBar(
                title: 'notifications.title'.tr(),
                showBackButton: true,
                onLeadingTap: () => Navigator.of(context).maybePop(),
                trailingLabel: state.unreadCount > 0
                    ? 'notifications.mark_all_read'.tr()
                    : null,
                onTrailingTap: state.unreadCount > 0
                    ? () => context.read<NotificationsBloc>().add(
                        const NotificationsAllMarkedRead(),
                      )
                    : null,
              ),
            ),
            Expanded(
              child: BlocConsumer<NotificationsBloc, NotificationsState>(
                listenWhen: (a, b) =>
                    a.markAllFailure != b.markAllFailure &&
                    b.markAllFailure != null,
                listener: (context, state) => showAppErrorSnackbar(
                  context: context,
                  title: state.markAllFailure!.localizedSafeMessage(),
                ),
                builder: (context, state) {
                  final bloc = context.read<NotificationsBloc>();
                  return RefreshIndicator(
                    onRefresh: () async =>
                        bloc.add(const NotificationsRefreshed()),
                    child: SanadPagedList<AppNotification>(
                      state: toPagingState(state.data),
                      fetchNextPage: () =>
                          bloc.add(const NotificationsNextPageRequested()),
                      itemBuilder: (context, item, index) => NotificationRow(
                        notification: item,
                        onTap: () => _open(context, item),
                      ),
                      separatorBuilder: (_, _) => const AppDivider(),
                      firstPageErrorIndicatorBuilder: (context) =>
                          AppGenericEmptyState(
                            title: 'notifications.error_title'.tr(),
                            description:
                                state.data.firstPageError
                                    ?.localizedSafeMessage() ??
                                'notifications.error_description'.tr(),
                          ),
                      newPageErrorIndicatorBuilder: (context) => Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(
                          child: Text('notifications.error_title'.tr()),
                        ),
                      ),
                      noItemsFoundIndicatorBuilder: (context) =>
                          AppGenericEmptyState(
                            title: 'notifications.empty_title'.tr(),
                            description: 'notifications.empty_description'.tr(),
                          ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, AppNotification notification) {
    context.read<NotificationsBloc>().add(
      NotificationMarkedRead(notification.id),
    );
    // A row with no subject — or an offer whose request id the server did not
    // include — has nowhere to go. Marking it read is the whole interaction.
    if (!notification.subject.isNavigable) return;
    resolveNavigator()?.openSubject(notification.subject);
  }
}
