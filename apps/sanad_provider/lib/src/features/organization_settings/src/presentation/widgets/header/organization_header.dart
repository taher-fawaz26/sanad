import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media/media.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_slot.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/identity_header/identity_header_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/components/organization_status_badge.dart';
import 'package:shared_ui/shared_ui.dart';

/// Organization identity header for the general settings view mode — Figma
/// `Identity-Header-Section` (`4253:25622`).
///
/// Facebook-style cover + circular logo with edit affordances. All media
/// tooling (pick / crop / zoom / rotate / view) is delegated to the generic
/// `media` package via [MediaCoordinator]; uploading is owned by
/// [IdentityHeaderBloc]. This widget only provides the bloc and maps its
/// state onto the pure [EditableImageHeader].
class OrganizationHeader extends StatefulWidget {
  const OrganizationHeader({
    super.key,
    this.coverUrl,
    this.logoUrl,
    this.name,
    this.summary,
    this.status = OrganizationProfileStatus.incomplete,
    this.onMediaUpdated,
  });

  final String? coverUrl;
  final String? logoUrl;
  final String? name;
  final String? summary;
  final OrganizationProfileStatus status;

  /// Fired once a cover/logo upload succeeds, with the new image URL — lets
  /// the parent (`OrganizationSettingsBloc`) sync its own copy of the
  /// profile so the change survives a subsequent reload instead of only
  /// living in this header's own [IdentityHeaderBloc].
  final void Function(OrganizationMediaSlot slot, String url)? onMediaUpdated;

  @override
  State<OrganizationHeader> createState() => _OrganizationHeaderState();
}

class _OrganizationHeaderState extends State<OrganizationHeader> {
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
  void didUpdateWidget(OrganizationHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `BlocProvider(create: ...)` only runs once per element — without this,
    // a cold-open's first frame (built with no image yet, e.g. the loading
    // skeleton profile or a still-in-flight cache/network read) seeds
    // IdentityHeaderBloc with null urls, and the real urls that arrive on a
    // later rebuild are silently dropped since the bloc is never re-seeded.
    // Re-seeding is skipped while a slot is mid-upload so it doesn't clobber
    // the optimistic/progress state the user is currently watching.
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
    return BlocProvider<IdentityHeaderBloc>.value(
      value: _bloc,
      child: _OrganizationHeaderView(
        name: widget.name,
        summary: widget.summary,
        status: widget.status,
        onMediaUpdated: widget.onMediaUpdated,
      ),
    );
  }
}

class _OrganizationHeaderView extends StatelessWidget {
  const _OrganizationHeaderView({
    this.name,
    this.summary,
    this.status = OrganizationProfileStatus.incomplete,
    this.onMediaUpdated,
  });

  final String? name;
  final String? summary;
  final OrganizationProfileStatus status;
  final void Function(OrganizationMediaSlot slot, String url)? onMediaUpdated;

  Future<void> _edit(
    BuildContext context,
    OrganizationMediaSlot slot,
  ) async {
    final bloc = context.read<IdentityHeaderBloc>();
    final slotState = bloc.state.slot(slot);
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IdentityHeaderBloc, IdentityHeaderState>(
      listenWhen: (previous, current) =>
          (previous.cover.status != RequestStatus.success &&
              current.cover.status == RequestStatus.success) ||
          (previous.logo.status != RequestStatus.success &&
              current.logo.status == RequestStatus.success),
      listener: (context, state) {
        final coverUrl = state.cover.imageUrl;
        if (state.cover.status == RequestStatus.success && coverUrl != null) {
          onMediaUpdated?.call(OrganizationMediaSlot.cover, coverUrl);
        }
        final logoUrl = state.logo.imageUrl;
        if (state.logo.status == RequestStatus.success && logoUrl != null) {
          onMediaUpdated?.call(OrganizationMediaSlot.logo, logoUrl);
        }
      },
      builder: (context, state) {
        return AppSectionCard(
          child: EditableImageHeader(
            title: name,
            subtitle: summary,
            badge: OrganizationStatusBadge(status: status),
            coverUrl: state.cover.imageUrl,
            avatarUrl: state.logo.imageUrl,
            coverBusy: state.cover.isBusy,
            avatarBusy: state.logo.isBusy,
            coverProgress: state.cover.progress,
            avatarProgress: state.logo.progress,
            onEditCover: () => _edit(context, OrganizationMediaSlot.cover),
            onEditAvatar: () => _edit(context, OrganizationMediaSlot.logo),
          ),
        );
      },
    );
  }
}
