import 'package:equatable/equatable.dart';

/// A plain media reference — used by service-request images, which carry
/// no primary/ordering concept (unlike [ProviderServiceImageEntity]).
class MediaRefEntity extends Equatable {
  const MediaRefEntity({required this.id, required this.url});

  final String id;
  final String url;

  @override
  List<Object?> get props => [id, url];
}
