import 'package:flutter_test/flutter_test.dart';
import 'package:services/src/data/models/provider_service_dto.dart';

void main() {
  group('ProviderServiceDto.fromJson', () {
    test(
      'parses the real GET /provider-services/:id detail response, '
      'including requests/revenue and the nested service.category',
      () {
        final json = {
          'id': 'b823f7bd-c350-4e47-a389-f198021a1845',
          'service': {
            'id': '778cb9c7-7012-4f4a-bcfa-277ba81b6554',
            'name': 'Leak Detection & Repair',
            'category': {
              'id': '18ec1c63-4db4-4714-9b0d-80bb8550442f',
              'name': 'Plumbing',
              'description':
                  'Leak repair, fixtures, and general '
                  'plumbing work.',
            },
          },
          'description': 'etdts dsygdsy uiwiew',
          'primaryImage': {
            'id': '97bc07fe-d9ab-459b-a053-e01cba919884',
            'mediaId': 'c8c09330-359c-478d-83d5-c43c5c392baa',
            'url': 'https://example.com/media/1.jpg',
            'isPrimary': true,
          },
          'requests': 0,
          'revenue': 0,
          'status': 'active',
          'createdAt': '2026-08-13T16:44:10.629Z',
          'updatedAt': '2026-08-13T16:44:10.629Z',
          'images': [
            {
              'id': '2d0c4eb6-dcc1-4c7d-b157-9f1ae4b25be8',
              'mediaId': 'da53d165-0d48-4dc4-8999-f8bbf802ee51',
              'url': 'https://example.com/media/2.jpg',
              'isPrimary': false,
            },
            {
              'id': '97bc07fe-d9ab-459b-a053-e01cba919884',
              'mediaId': 'c8c09330-359c-478d-83d5-c43c5c392baa',
              'url': 'https://example.com/media/1.jpg',
              'isPrimary': true,
            },
          ],
        };

        final dto = ProviderServiceDto.fromJson(json);

        expect(dto.id, 'b823f7bd-c350-4e47-a389-f198021a1845');
        expect(dto.serviceId, '778cb9c7-7012-4f4a-bcfa-277ba81b6554');
        expect(dto.serviceName, 'Leak Detection & Repair');
        expect(dto.category.name, 'Plumbing');
        expect(dto.description, 'etdts dsygdsy uiwiew');
        expect(dto.requests, 0);
        expect(dto.revenue, 0);
        // Full `images` array present → used as-is (2 entries), not
        // collapsed to just `primaryImage`.
        expect(dto.images, hasLength(2));
        expect(
          dto.primaryImage?.id,
          '97bc07fe-d9ab-459b-a053-e01cba919884',
        );
      },
    );

    test(
      'defaults requests/revenue to 0 when absent (list-row shape)',
      () {
        final json = {
          'id': 's1',
          'serviceId': 'catalog-1',
          'serviceName': 'Plumbing service',
          'category': {
            'id': 'cat-1',
            'name': 'Home',
            'description': null,
          },
          'description': null,
          'status': 'active',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        };

        final dto = ProviderServiceDto.fromJson(json);

        expect(dto.requests, 0);
        expect(dto.revenue, 0);
      },
    );

    test(
      'falls back to wrapping primaryImage as a single-item list when '
      'the full images array is absent (list-row shape)',
      () {
        final json = {
          'id': 's1',
          'serviceId': 'catalog-1',
          'serviceName': 'Plumbing service',
          'category': {'id': 'cat-1', 'name': 'Home', 'description': null},
          'description': null,
          'status': 'active',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
          'primaryImage': {
            'id': 'img-1',
            'mediaId': 'media-1',
            'url': 'https://example.com/media/1.jpg',
            'isPrimary': true,
          },
        };

        final dto = ProviderServiceDto.fromJson(json);

        expect(dto.images, hasLength(1));
        expect(dto.primaryImage?.id, 'img-1');
      },
    );

    test(
      'no images and no primaryImage yields an empty images list, not a '
      'parse error',
      () {
        final json = {
          'id': 's1',
          'serviceId': 'catalog-1',
          'serviceName': 'Plumbing service',
          'category': {'id': 'cat-1', 'name': 'Home', 'description': null},
          'description': null,
          'status': 'active',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        };

        final dto = ProviderServiceDto.fromJson(json);

        expect(dto.images, isEmpty);
        expect(dto.primaryImage, isNull);
      },
    );

    test('parses non-zero requests/revenue', () {
      final json = {
        'id': 's1',
        'serviceId': 'catalog-1',
        'serviceName': 'Plumbing service',
        'category': {'id': 'cat-1', 'name': 'Home', 'description': null},
        'description': null,
        'status': 'active',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'requests': 12,
        'revenue': 450.5,
      };

      final dto = ProviderServiceDto.fromJson(json);

      expect(dto.requests, 12);
      expect(dto.revenue, 450.5);
    });
  });
}
