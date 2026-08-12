import 'package:core/core.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';

class ProviderServiceImageDto extends ProviderServiceImageEntity
    implements EntityConverter<ProviderServiceImageEntity> {
  const ProviderServiceImageDto({
    required super.id,
    required super.mediaId,
    required super.url,
    required super.isPrimary,
  });

  factory ProviderServiceImageDto.fromJson(Map<String, dynamic> json) =>
      ProviderServiceImageDto(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        url: json['url'] as String,
        isPrimary: json['isPrimary'] as bool? ?? false,
      );

  @override
  ProviderServiceImageEntity toEntity() => ProviderServiceImageEntity(
    id: id,
    mediaId: mediaId,
    url: url,
    isPrimary: isPrimary,
  );
}
