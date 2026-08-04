import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media/media.dart';
import 'package:organization_settings/src/domain/entities/organization_media_slot.dart';
import 'package:organization_settings/src/presentation/bloc/identity_header/identity_header_bloc.dart';
import 'package:organization_settings/src/presentation/widgets/components/settings_section_card.dart';

/// Organization identity header for the general settings view mode.
///
/// Facebook-style cover + circular logo with edit affordances. All media
/// tooling (pick / crop / zoom / rotate / view) is delegated to the generic
/// `media` package via [MediaCoordinator]; uploading is owned by
/// [IdentityHeaderBloc]. This widget only provides the bloc and maps its state
/// onto the pure [EditableImageHeader].
class OrganizationHeader extends StatelessWidget {
  const OrganizationHeader({
    super.key,
    this.coverUrl,
    this.logoUrl,
    this.name,
    this.summary,
  });

  final String? coverUrl;
  final String? logoUrl;
  final String? name;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IdentityHeaderBloc>(
      create: (_) => sl<IdentityHeaderBloc>()
        ..add(
          IdentityHeaderInitialized(coverUrl: coverUrl, logoUrl: logoUrl),
        ),
      child: _OrganizationHeaderView(name: name, summary: summary),
    );
  }
}

class _OrganizationHeaderView extends StatelessWidget {
  const _OrganizationHeaderView({this.name, this.summary});

  final String? name;
  final String? summary;

  Future<void> _edit(
    BuildContext context,
    OrganizationMediaSlot slot,
  ) async {
    final bloc = context.read<IdentityHeaderBloc>();
    final slotState = bloc.state.slot(slot);
    final isCover = slot == OrganizationMediaSlot.cover;

    final result = await MediaCoordinator.start(
      context,
      actionSheetTitle: (isCover
              ? 'media.edit_cover'
              : 'media.edit_photo')
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
    return BlocBuilder<IdentityHeaderBloc, IdentityHeaderState>(
      builder: (context, state) {
        return SettingsSectionCard(
          child: EditableImageHeader(
            title: name,
            subtitle: summary,
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
