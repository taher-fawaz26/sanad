import 'package:flutter_test/flutter_test.dart';
import 'package:services/src/data/models/service_analytics_dto.dart';
import 'package:services/src/domain/entities/service_category_summary_entity.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/presentation/models/provider_service_card_data.dart';

final _service = ServiceRecordEntity(
  id: 'd967bc92-67aa-495d-8893-e83499753aa3',
  name: 'Furniture Assembly & Repairs',
  description: null,
  price: 0,
  isActive: true,
  category: const ServiceCategorySummaryEntity(
    id: 'cat-1',
    name: 'Home Services',
    slug: 'home-services',
    icon: null,
  ),
  media: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('ServiceAnalyticsDto.fromJson', () {
    test('parses perService rows including completion fields', () {
      final entity = ServiceAnalyticsDto.fromJson({
        'dataAvailable': false,
        'overall': {'totalRequests': 0, 'totalRevenue': 0},
        'completion': {
          'completedCount': 0,
          'cancelledCount': 0,
          'completionRate': 0,
        },
        'perService': [
          {
            'serviceId': 'd967bc92-67aa-495d-8893-e83499753aa3',
            'name': 'Furniture Assembly & Repairs',
            'requestCount': 0,
            'revenue': 0,
            'completedCount': 0,
            'cancelledCount': 0,
            'completionRate': 0,
          },
        ],
      });

      expect(entity.dataAvailable, isFalse);
      expect(entity.perService, hasLength(1));
      final row = entity.perService.single;
      expect(row.serviceId, 'd967bc92-67aa-495d-8893-e83499753aa3');
      expect(row.requestCount, 0);
      expect(row.revenue, 0);
      expect(row.completedCount, 0);
      expect(row.cancelledCount, 0);
      expect(row.completionRate, 0);
    });
  });

  group('ProviderServiceCardData.fromEntity', () {
    test(
      'shows "—" when no matching perServiceMetrics row is provided',
      () {
        final data = ProviderServiceCardData.fromEntity(_service);

        expect(data.requestsCount, '—');
        expect(data.revenueLabel, '—');
      },
    );

    test(
      'shows real per-service numbers (including 0) once analytics loads, '
      'regardless of dataAvailable — product decision, not a fabrication',
      () {
        final entity = ServiceAnalyticsDto.fromJson({
          'dataAvailable': false,
          'overall': {'totalRequests': 0, 'totalRevenue': 0},
          'completion': {
            'completedCount': 0,
            'cancelledCount': 0,
            'completionRate': 0,
          },
          'perService': [
            {
              'serviceId': _service.id,
              'name': _service.name,
              'requestCount': 0,
              'revenue': 0,
              'completedCount': 0,
              'cancelledCount': 0,
              'completionRate': 0,
            },
          ],
        });

        final data = ProviderServiceCardData.fromEntity(
          _service,
          perServiceMetrics: entity.perService.single,
        );

        expect(data.requestsCount, '0');
        expect(data.revenueLabel, isNot('—'));
      },
    );
  });
}
