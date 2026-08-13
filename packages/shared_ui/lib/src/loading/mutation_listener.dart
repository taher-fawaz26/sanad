import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_ui/src/loading/app_progress.dart';

/// Reusable [BlocListener] that maps a BLoC's [RequestStatus] onto the
/// centralized [AppProgress] blocking dialog.
///
/// Replaces the hand-rolled `_onBlocStateChanged` + visibility-latch +
/// show/dismiss trio that each mutation screen used to duplicate:
///
/// ```dart
/// MutationListener<AddWorkerBloc, AddWorkerState>(
///   status: (s) => s.status,
///   title: (ctx) => 'workers.add_worker.submitting_title'.tr(),
///   onSuccess: (ctx, s) => Navigator.of(ctx).pop(),
///   onFailure: (ctx, s) => showError(ctx, s.failure!.message),
///   child: ...,
/// )
/// ```
///
/// * `loading` → shows the dialog (idempotent via [AppProgress]).
/// * `success` / `failure` → dismisses the dialog exactly once, then invokes
///   the matching callback if the context is still mounted.
/// * `initial` → no-op.
///
/// By default it only reacts on status *transitions*, so unrelated state
/// changes (e.g. form edits) never re-trigger the dialog.
class MutationListener<B extends StateStreamable<S>, S>
    extends StatelessWidget {
  const MutationListener({
    required this.status,
    required this.title,
    required this.child,
    super.key,
    this.description,
    this.onSuccess,
    this.onFailure,
    this.listenWhen,
  });

  /// Extracts the mutation lifecycle status from the state.
  final RequestStatus Function(S state) status;

  /// Dialog title, resolved lazily so it can read localization from context.
  final String Function(BuildContext context) title;

  /// Optional dialog description.
  final String Function(BuildContext context)? description;

  /// Invoked once when the mutation succeeds (dialog already dismissed).
  final void Function(BuildContext context, S state)? onSuccess;

  /// Invoked once when the mutation fails (dialog already dismissed).
  final void Function(BuildContext context, S state)? onFailure;

  /// Overrides the default "react only on status change" gate.
  final bool Function(S previous, S current)? listenWhen;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listenWhen: listenWhen ??
          (previous, current) => status(previous) != status(current),
      listener: (context, state) {
        switch (status(state)) {
          case RequestStatus.loading:
            AppProgress.show(
              context,
              title: title(context),
              description: description?.call(context),
            );
          case RequestStatus.success:
            AppProgress.dismiss();
            if (context.mounted) onSuccess?.call(context, state);
          case RequestStatus.failure:
            AppProgress.dismiss();
            if (context.mounted) onFailure?.call(context, state);
          case RequestStatus.initial:
            break;
        }
      },
      child: child,
    );
  }
}
