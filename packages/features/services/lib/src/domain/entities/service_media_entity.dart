import 'package:equatable/equatable.dart';

/// `ServiceMediaDto` — one uploaded media item attached to a service or a
/// service request. `type` is a plain backend string (e.g. `"image"`), not a
/// fixed enum in the live schema.
class ServiceMediaEntity extends Equatable {
  const ServiceMediaEntity({
    required this.id,
    required this.url,
    required this.type,
  });

  final String id;
  final String url;
  final String type;

  @override
  List<Object?> get props => [id, url, type];
}
