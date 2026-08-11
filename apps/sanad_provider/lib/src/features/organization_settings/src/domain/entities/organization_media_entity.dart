import 'package:equatable/equatable.dart';

/// The backend-assigned identifiers for an uploaded organization image.
class OrganizationMediaEntity extends Equatable {
  const OrganizationMediaEntity({this.id, this.url});

  final String? id;
  final String? url;

  @override
  List<Object?> get props => [id, url];
}
