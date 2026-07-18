import 'package:flutter_test/flutter_test.dart';
import 'package:services/src/data/models/service_dto.dart';

/// Real backend response shape from `GET /api/v1/provider/services`.
///
/// Services are grouped by category. Each service item contains a nested
/// `service` object (the global catalog entry) whose `name` is the display
/// name. The top-level `id` is the provider-service record UUID — this is
/// the value `CreateBranchDto.serviceIds` expects.
const _kBackendResponse = <String, dynamic>{
  'data': [
    {
      'category': {
        'id': '111e8400-e29b-41d4-a716-446655440002',
        'name': 'خدمات السيارات',
        'icon': 'car',
      },
      'services': [
        {
          'id': '14506a7c-c69f-4b3c-a9f6-c8d0140c5637',
          'createdAt': '2026-06-13T17:20:17.260Z',
          'updatedAt': '2026-07-12T12:14:47.766Z',
          'deletedAt': null,
          'description': {'ar': 'test arabic', 'en': 'test english'},
          'isActive': true,
          'isEmergencyEnabled': false,
          'service': {
            'id': '222e8400-e29b-41d4-a716-446655440002',
            'createdAt': '2026-03-18T21:36:11.667Z',
            'updatedAt': '2026-03-18T21:36:11.667Z',
            'deletedAt': null,
            'name': 'إصلاح السيارات',
            'depth': 0,
            'sortOrder': 0,
            'isLeaf': true,
            'isActive': true,
          },
          'media': <dynamic>[],
        },
        {
          'id': 'aaa11111-1111-1111-1111-111111111111',
          'createdAt': '2026-06-13T17:20:17.260Z',
          'updatedAt': '2026-06-13T17:20:17.260Z',
          'deletedAt': null,
          'description': {'ar': '', 'en': ''},
          'isActive': true,
          'isEmergencyEnabled': false,
          'service': {
            'id': 'bbb22222-2222-2222-2222-222222222222',
            'createdAt': '2026-03-18T21:36:11.667Z',
            'updatedAt': '2026-03-18T21:36:11.667Z',
            'deletedAt': null,
            'name': 'غسيل سيارات',
            'depth': 0,
            'sortOrder': 1,
            'isLeaf': true,
            'isActive': true,
          },
          'media': <dynamic>[],
        },
      ],
    },
    {
      'category': {
        'id': 'cat-002',
        'name': 'صيانة منزلية',
        'icon': 'home',
      },
      'services': [
        {
          'id': 'ccc33333-3333-3333-3333-333333333333',
          'createdAt': '2026-06-13T17:20:17.260Z',
          'updatedAt': '2026-06-13T17:20:17.260Z',
          'deletedAt': null,
          'description': {'ar': '', 'en': ''},
          'isActive': true,
          'isEmergencyEnabled': false,
          'service': {
            'id': 'ddd44444-4444-4444-4444-444444444444',
            'name': 'سباكة',
          },
          'media': <dynamic>[],
        },
      ],
    },
    {
      'category': {
        'id': 'cat-003',
        'name': 'فئة فارغة',
      },
      'services': <dynamic>[],
    },
  ],
};

List<ServiceDto> _parse(dynamic raw) {
  final json = raw as Map<String, dynamic>;
  final groups = json['data'] as List<dynamic>;
  final services = <ServiceDto>[];
  for (final group in groups) {
    final entry = group as Map<String, dynamic>;
    final categoryJson = entry['category'] as Map<String, dynamic>;
    final categoryName = categoryJson['name'] as String;
    final items = entry['services'] as List<dynamic>;
    for (final item in items) {
      services.add(
        ServiceDto.fromJsonWithCategory(
          item as Map<String, dynamic>,
          categoryName,
        ),
      );
    }
  }
  return services;
}

void main() {
  group('Service response parser', () {
    test('flattens grouped-by-category response into ServiceDto list', () {
      final services = _parse(_kBackendResponse);

      expect(services, hasLength(3));
    });

    test('uses top-level id (provider service), not service.id (catalog)', () {
      final services = _parse(_kBackendResponse);

      expect(services[0].id, '14506a7c-c69f-4b3c-a9f6-c8d0140c5637');
      expect(services[0].id, isNot('222e8400-e29b-41d4-a716-446655440002'));
    });

    test('reads name from nested service object', () {
      final services = _parse(_kBackendResponse);

      expect(services[0].name, 'إصلاح السيارات');
      expect(services[1].name, 'غسيل سيارات');
      expect(services[2].name, 'سباكة');
    });

    test('each service carries its parent category name', () {
      final services = _parse(_kBackendResponse);

      expect(services[0].category, 'خدمات السيارات');
      expect(services[1].category, 'خدمات السيارات');
      expect(services[2].category, 'صيانة منزلية');
    });

    test('empty category group produces no services', () {
      final services = _parse(_kBackendResponse);

      expect(services.where((s) => s.category == 'فئة فارغة'), isEmpty);
    });

    test('toEntity preserves all fields', () {
      final dto = _parse(_kBackendResponse).first;
      final entity = dto.toEntity();

      expect(entity.id, dto.id);
      expect(entity.name, dto.name);
      expect(entity.category, dto.category);
    });

    test('empty data array produces empty list', () {
      const empty = <String, dynamic>{'data': <dynamic>[]};

      expect(_parse(empty), isEmpty);
    });
  });
}
