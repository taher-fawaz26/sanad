import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:media/media.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_slot.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/identity_header/identity_header_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/components/organization_status_badge.dart';
import 'package:shared_ui/shared_ui.dart';

/// Facebook-style collapsing identity header for the general-settings page,
/// implemented as a pinned [SliverPersistentHeader].
///
/// The delegate ([_ProfileHeaderDelegate]) drives a *continuous* collapse
/// straight from the sliver protocol's `shrinkOffset` — no scroll listeners,
/// no `setState` per tick, and no arbitrary threshold jumps. As the header
/// shrinks the cover slides up and fades, the avatar scales down and docks
/// toward the leading (RTL-aware) edge, and the identity name/badge slide into
/// a compact pinned bar that stays usable beneath the app bar. Scroll-linked
/// transforms track the gesture rather than a timed animation, so there is no
/// `AnimationController` to leak and nothing for reduced-motion to gate here.
///
/// This widget owns the [IdentityHeaderBloc] (cover/logo upload lifecycle) so
/// all existing edit / progress / retry / cancel behavior is preserved; the
/// generic `media` widgets ([MediaCoverPhoto]/[MediaAvatar]) are composed
/// directly rather than reusing the shared [EditableImageHeader], which has a
/// fixed non-collapsing layout used by other identity surfaces.
class OrganizationProfileSliverHeader extends StatefulWidget {
  const OrganizationProfileSliverHeader({
    super.key,
    this.coverUrl,
    this.logoUrl,
    this.name,
    this.status = OrganizationProfileStatus.incomplete,
    this.isLoading = false,
    this.onMediaUpdated,
  });

  final String? coverUrl;
  final String? logoUrl;
  final String? name;
  final OrganizationProfileStatus status;

  /// Shows shimmer skeletons for cover/avatar/name during the initial load.
  final bool isLoading;

  /// Fired once a cover/logo upload succeeds, with the new image URL — lets
  /// the parent bloc sync its own copy of the profile so the change survives a
  /// reload. Mirrors the previous `OrganizationHeader` contract.
  final void Function(OrganizationMediaSlot slot, String? url)? onMediaUpdated;

  @override
  State<OrganizationProfileSliverHeader> createState() =>
      _OrganizationProfileSliverHeaderState();
}

class _OrganizationProfileSliverHeaderState
    extends State<OrganizationProfileSliverHeader> {
  late final IdentityHeaderBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<IdentityHeaderBloc>()
      ..add(
        IdentityHeaderInitialized(
          coverUrl: widget.coverUrl,
          logoUrl: widget.logoUrl,
        ),
      );
  }

  @override
  void didUpdateWidget(OrganizationProfileSliverHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `sl<IdentityHeaderBloc>()` is seeded once in initState — re-seed when the
    // real cover/logo urls arrive on a later rebuild (cold-open's first frame
    // has none), unless a slot is mid-upload (don't clobber the optimistic
    // progress state the user is watching). Same guard as the old header.
    final coverChanged = oldWidget.coverUrl != widget.coverUrl;
    final logoChanged = oldWidget.logoUrl != widget.logoUrl;
    if (!coverChanged && !logoChanged) return;
    if (_bloc.state.cover.isBusy || _bloc.state.logo.isBusy) return;
    _bloc.add(
      IdentityHeaderInitialized(
        coverUrl: widget.coverUrl,
        logoUrl: widget.logoUrl,
      ),
    );
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ProfileHeaderDelegate(
        bloc: _bloc,
        name: widget.name,
        status: widget.status,
        isLoading: widget.isLoading,
        backgroundColor: context.appColors.surface,
        dividerColor: context.appColors.border,
        onMediaUpdated: widget.onMediaUpdated,
      ),
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ProfileHeaderDelegate({
    required this.bloc,
    required this.name,
    required this.status,
    required this.isLoading,
    required this.backgroundColor,
    required this.dividerColor,
    required this.onMediaUpdated,
  });

  final IdentityHeaderBloc bloc;
  final String? name;
  final OrganizationProfileStatus status;
  final bool isLoading;
  final Color backgroundColor;
  final Color dividerColor;
  final void Function(OrganizationMediaSlot slot, String? url)? onMediaUpdated;

  // ── Geometry (design-spec dp; const so the extents are deterministic) ──
  static const double _hPad = AppSpacingDp.xl; // 20
  static const double _coverH = 120;
  static const double _coverRadius = 12;
  static const double _expandedAvatar = 76;
  static const double _compactAvatar = 40;
  static const double _cardTopPad = AppSpacingDp.lg; // 16
  static const double _cardBottomPad = AppSpacingDp.lg; // 16
  static const double _avatarInset = AppSpacingDp.md; // 12 past _hPad
  static const double _avatarNameGap = AppSpacingDp.md; // 12
  static const double _compactVPad = AppSpacingDp.sm; // 8
  static const double _compactNameGap = AppSpacingDp.sm; // 8
  static const double _avatarOverlap = 40; // avatar rise into the cover
  static const double _nameLineH = 24;

  // Expanded targets (measured from the header box's top).
  static const double _coverTopE = _cardTopPad; // 16
  static const double _coverBottomE = _coverTopE + _coverH; // 136
  static const double _avatarTopE = _coverBottomE - _avatarOverlap; // 96
  static const double _avatarBottomE = _avatarTopE + _expandedAvatar; // 172
  static const double _avatarStartE = _hPad + _avatarInset; // 32
  static const double _nameStartE =
      _avatarStartE + _expandedAvatar + _avatarNameGap; // 120
  static const double _nameTopE = 122;

  // Compact targets.
  static const double _avatarTopC = _compactVPad; // 8
  static const double _avatarStartC = _hPad; // 20
  static const double _nameStartC =
      _avatarStartC + _compactAvatar + _compactNameGap; // 68

  @override
  double get maxExtent => _avatarBottomE + _cardBottomPad; // 188

  @override
  double get minExtent => _compactAvatar + 2 * _compactVPad; // 56

  double get _nameTopC => (minExtent - _nameLineH) / 2; // 16

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    // 1.0 fully expanded → 0.0 fully collapsed. Straight from shrinkOffset.
    final t = (1 - (shrinkOffset / range)).clamp(0.0, 1.0);
    final eased = applyCollapseCurve(t);

    double lerp(double collapsed, double expanded) =>
        ui.lerpDouble(collapsed, expanded, eased)!;

    final coverTop = _coverTopE - shrinkOffset; // slides up with the content
    final coverOpacity = mapCollapseRange(t, inMin: 0.35, inMax: 1);
    final avatarSize = lerp(_compactAvatar, _expandedAvatar);
    final avatarTop = lerp(_avatarTopC, _avatarTopE);
    final avatarStart = lerp(_avatarStartC, _avatarStartE);
    final nameTop = lerp(_nameTopC, _nameTopE);
    final nameStart = lerp(_nameStartC, _nameStartE);

    return BlocProvider<IdentityHeaderBloc>.value(
      value: bloc,
      child: _ProfileHeaderContent(
        name: name,
        status: status,
        isLoading: isLoading,
        backgroundColor: backgroundColor,
        dividerColor: dividerColor,
        onMediaUpdated: onMediaUpdated,
        coverTop: coverTop,
        coverOpacity: coverOpacity,
        avatarSize: avatarSize,
        avatarTop: avatarTop,
        avatarStart: avatarStart,
        nameTop: nameTop,
        nameStart: nameStart,
        badgeOpacity: eased,
        // The compact bar separator only appears as the header collapses.
        dividerOpacity: 1 - eased,
        coverRadius: _coverRadius,
        coverHeight: _coverH,
        hPad: _hPad,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.bloc != bloc ||
        oldDelegate.name != name ||
        oldDelegate.status != status ||
        oldDelegate.isLoading != isLoading ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.dividerColor != dividerColor ||
        oldDelegate.onMediaUpdated != onMediaUpdated;
  }
}

/// Pure layout for one collapse frame. All scroll-derived geometry is passed
/// in; the only reactive piece is the [IdentityHeaderBloc] state (upload
/// progress / failure), read via [BlocConsumer] so an in-flight upload updates
/// the cover/avatar without needing a scroll tick.
class _ProfileHeaderContent extends StatelessWidget {
  const _ProfileHeaderContent({
    required this.name,
    required this.status,
    required this.isLoading,
    required this.backgroundColor,
    required this.dividerColor,
    required this.onMediaUpdated,
    required this.coverTop,
    required this.coverOpacity,
    required this.avatarSize,
    required this.avatarTop,
    required this.avatarStart,
    required this.nameTop,
    required this.nameStart,
    required this.badgeOpacity,
    required this.dividerOpacity,
    required this.coverRadius,
    required this.coverHeight,
    required this.hPad,
  });

  final String? name;
  final OrganizationProfileStatus status;
  final bool isLoading;
  final Color backgroundColor;
  final Color dividerColor;
  final void Function(OrganizationMediaSlot slot, String? url)? onMediaUpdated;
  final double coverTop;
  final double coverOpacity;
  final double avatarSize;
  final double avatarTop;
  final double avatarStart;
  final double nameTop;
  final double nameStart;
  final double badgeOpacity;
  final double dividerOpacity;
  final double coverRadius;
  final double coverHeight;
  final double hPad;

  Future<void> _edit(BuildContext context, OrganizationMediaSlot slot) async {
    final bloc = context.read<IdentityHeaderBloc>();
    final slotState = bloc.state.slot(slot);
    if (slotState.isBusy) return;
    final isCover = slot == OrganizationMediaSlot.cover;

    final result = await MediaCoordinator.start(
      context,
      actionSheetTitle: (isCover ? 'media.edit_cover' : 'media.edit_photo')
          .tr(),
      editorConfig: isCover
          ? const MediaEditorConfig.cover()
          : const MediaEditorConfig.avatar(),
      existingImageUrl: slotState.imageUrl,
    );

    switch (result) {
      case MediaEdited(:final media):
        bloc.add(IdentityHeaderMediaSelected(slot: slot, media: media));
      case MediaRemoveRequested():
        bloc.add(IdentityHeaderMediaRemoved(slot: slot));
      case MediaViewed():
      case MediaCancelled():
        break;
    }
  }

  void _cancel(BuildContext context, OrganizationMediaSlot slot) =>
      context.read<IdentityHeaderBloc>().add(
        IdentityHeaderUploadCancelled(slot: slot),
      );

  void _retry(BuildContext context, OrganizationMediaSlot slot) =>
      context.read<IdentityHeaderBloc>().add(
        IdentityHeaderUploadRetried(slot: slot),
      );

  String? _errorMessage(IdentityMediaSlotState slotState) {
    if (!slotState.hasError) return null;
    final message = slotState.failure?.localizedMessage();
    return (message == null || message.trim().isEmpty)
        ? 'media.upload_failed'.tr()
        : message;
  }

  /// A failure with nothing to retry — a removal keeps no `lastMedia`, so
  /// there is no picked image for a retry affordance to re-send. These
  /// must never render as the persistent on-image [MediaFailureOverlay] (there
  /// is no action the overlay's retry affordance could offer), so they're
  /// surfaced once as a snackbar instead — see the `listener` below.
  static bool _isNonRetryableFailure(IdentityMediaSlotState slotState) =>
      slotState.hasError && !slotState.canRetry;

  void _showNonRetryableFailureSnackbar(
    BuildContext context,
    OrganizationMediaSlot slot,
    IdentityMediaSlotState slotState,
  ) {
    showAppErrorSnackbar(
      context: context,
      title: _errorMessage(slotState) ?? 'media.upload_failed'.tr(),
    );
    // Consume it immediately so the failure never lingers in state — no
    // overlay was ever shown for it, and nothing needs a navigate-away/back
    // to "recover" since there is nothing left to recover from.
    context.read<IdentityHeaderBloc>().add(
      IdentityHeaderFailureAcknowledged(slot: slot),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IdentityHeaderBloc, IdentityHeaderState>(
      listenWhen: (previous, current) =>
          (previous.cover.status != RequestStatus.success &&
              current.cover.status == RequestStatus.success) ||
          (previous.logo.status != RequestStatus.success &&
              current.logo.status == RequestStatus.success) ||
          (!_isNonRetryableFailure(previous.cover) &&
              _isNonRetryableFailure(current.cover)) ||
          (!_isNonRetryableFailure(previous.logo) &&
              _isNonRetryableFailure(current.logo)),
      listener: (context, state) {
        // A success with a null url is a *removal*, and has to be forwarded
        // like any other change: skipping it (the previous `!= null` guard)
        // left the deleted image in the settings bloc and its cache, so the
        // next refresh brought it back.
        if (state.cover.status == RequestStatus.success) {
          onMediaUpdated?.call(
            OrganizationMediaSlot.cover,
            state.cover.imageUrl,
          );
        }
        if (state.logo.status == RequestStatus.success) {
          onMediaUpdated?.call(OrganizationMediaSlot.logo, state.logo.imageUrl);
        }
        if (_isNonRetryableFailure(state.cover)) {
          _showNonRetryableFailureSnackbar(
            context,
            OrganizationMediaSlot.cover,
            state.cover,
          );
        }
        if (_isNonRetryableFailure(state.logo)) {
          _showNonRetryableFailureSnackbar(
            context,
            OrganizationMediaSlot.logo,
            state.logo,
          );
        }
      },
      builder: (context, state) {
        return DecoratedBox(
          decoration: BoxDecoration(color: backgroundColor),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover — slides up and fades as the header collapses; ignore
              // taps once it's effectively invisible.
              PositionedDirectional(
                start: hPad,
                end: hPad,
                top: coverTop,
                height: coverHeight,
                child: IgnorePointer(
                  ignoring: coverOpacity < 0.05,
                  child: Opacity(
                    opacity: coverOpacity,
                    child: MediaCoverPhoto(
                      imageUrl: state.cover.imageUrl,
                      isLoading: isLoading,
                      isBusy: state.cover.isBusy,
                      // Only a retryable (upload) failure gets the
                      // persistent on-image overlay — a non-retryable one
                      // (e.g. remove) is surfaced as a snackbar instead, see
                      // `_isNonRetryableFailure`.
                      hasFailed: state.cover.canRetry,
                      progress: state.cover.progress,
                      errorMessage: state.cover.canRetry
                          ? _errorMessage(state.cover)
                          : null,
                      height: coverHeight,
                      borderRadius: BorderRadius.circular(coverRadius),
                      onEditTap: () =>
                          _edit(context, OrganizationMediaSlot.cover),
                      onCancel: () =>
                          _cancel(context, OrganizationMediaSlot.cover),
                      onRetry: state.cover.canRetry
                          ? () => _retry(context, OrganizationMediaSlot.cover)
                          : null,
                    ),
                  ),
                ),
              ),
              // Compact-bar separator — fades in only when collapsed.
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: Opacity(
                  opacity: dividerOpacity.clamp(0.0, 1.0),
                  child: Container(height: 1, color: dividerColor),
                ),
              ),
              // Avatar — scales + docks continuously. Sized (not just scaled)
              // so the edit affordance stays hit-testable; the image itself is
              // cached by URL so re-sizing never re-downloads.
              PositionedDirectional(
                start: avatarStart,
                top: avatarTop,
                child: MediaAvatar(
                  imageUrl: state.logo.imageUrl,
                  isLoading: isLoading,
                  isBusy: state.logo.isBusy,
                  // See the matching comment on `MediaCoverPhoto` above.
                  hasFailed: state.logo.canRetry,
                  progress: state.logo.progress,
                  errorMessage: state.logo.canRetry
                      ? _errorMessage(state.logo)
                      : null,
                  size: avatarSize,
                  onEditTap: () => _edit(context, OrganizationMediaSlot.logo),
                  onCancel: () => _cancel(context, OrganizationMediaSlot.logo),
                  onRetry: state.logo.canRetry
                      ? () => _retry(context, OrganizationMediaSlot.logo)
                      : null,
                ),
              ),
              // Identity name + status badge — slides beside the avatar; the
              // badge fades with the cover, the name stays legible throughout.
              PositionedDirectional(
                start: nameStart,
                top: nameTop,
                end: hPad,
                child: _IdentityText(
                  name: name,
                  status: status,
                  isLoading: isLoading,
                  badgeOpacity: badgeOpacity,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IdentityText extends StatelessWidget {
  const _IdentityText({
    required this.name,
    required this.status,
    required this.isLoading,
    required this.badgeOpacity,
  });

  final String? name;
  final OrganizationProfileStatus status;
  final bool isLoading;
  final double badgeOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    if (isLoading) {
      return AppShimmer(
        child: ShimmerBox(width: 160, height: AppSpacing.lg),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name != null && name!.isNotEmpty)
          Text(
            name!,
            style: typography.title3.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        SizedBox(height: AppSpacing.sm),
        Opacity(
          opacity: badgeOpacity.clamp(0.0, 1.0),
          child: OrganizationStatusBadge(status: status),
        ),
      ],
    );
  }
}
