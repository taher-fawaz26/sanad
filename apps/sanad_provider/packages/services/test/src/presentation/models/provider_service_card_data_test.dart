import 'package:flutter_test/flutter_test.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/presentation/models/provider_service_card_data.dart';

final _service = ProviderServiceEntity(
  id: 'd967bc92-67aa-495d-8893-e83499753aa3',
  serviceId: 'catalog-1',
  serviceName: 'Furniture Assembly & Repairs',
  category: const CategoryRefEntity(
    id: 'cat-1',
    name: 'Home Services',
    description: null,
  ),
  description: null,
  status: ProviderServiceStatus.active,
  images: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('ProviderServiceCardData.fromEntity', () {
    test('maps catalog service name, category, and status', () {
      final data = ProviderServiceCardData.fromEntity(_service);

      expect(data.id, _service.id);
      expect(data.name, 'Furniture Assembly & Repairs');
      expect(data.category, 'Home Services');
      expect(data.isActive, isTrue);
      expect(data.coverImageUrl, isNull);
      // Static placeholders — no price/revenue or per-card request count
      // exists on the new contract yet.
      expect(data.requestsCount, '0');
      expect(data.revenueLabel, '0 services.currency_aed');
    });

    test('uses the primary image as the cover image', () {
      final withImages = ProviderServiceEntity(
        id: _service.id,
        serviceId: _service.serviceId,
        serviceName: _service.serviceName,
        category: _service.category,
        description: _service.description,
        status: ProviderServiceStatus.inactive,
        images: const [
          ProviderServiceImageEntity(
            id: 'img-1',
            mediaId: 'media-1',
            url: 'https://example.com/1.jpg',
            isPrimary: false,
          ),
          ProviderServiceImageEntity(
            id: 'img-2',
            mediaId: 'media-2',
            url: 'https://example.com/2.jpg',
            isPrimary: true,
          ),
        ],
        createdAt: _service.createdAt,
        updatedAt: _service.updatedAt,
      );

      final data = ProviderServiceCardData.fromEntity(withImages);

      expect(data.coverImageUrl, 'https://example.com/2.jpg');
      expect(data.isActive, isFalse);
    });
  });
}
