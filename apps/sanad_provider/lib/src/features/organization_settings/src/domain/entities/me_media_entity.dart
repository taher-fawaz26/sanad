import 'package:equatable/equatable.dart';

/// A lean media reference — `MeMediaDto` (`{id, url}`), used only by
/// `GET /settings`'s `businessProfile.coverImage`/`.profileImage`.
///
/// Deliberately distinct from [MediaEntity]: unlike the legal-document media
/// (`LegalDataMediaResponseDto`) or the historical
/// `ServiceProviderMediaResponseDto`, `MeMediaDto` carries no
/// `originalName`/`mimeType`.
class MeMediaEntity extends Equatable {
  const MeMediaEntity({required this.id, required this.url});

  final String id;
  final String url;

  @override
  List<Object?> get props => [id, url];
}
