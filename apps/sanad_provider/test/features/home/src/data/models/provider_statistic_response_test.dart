import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/home/src/data/models/provider_statistic_response.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';

void main() {
  group('ProviderStatisticResponse.fromJson', () {
    test('parses a full statistic entry', () {
      final response = ProviderStatisticResponse.fromJson({
        'key': 'branches',
        'name': 'Branches',
        'icon': 'fa-solid fa-store',
        'value': 2,
      });

      expect(response.key, 'branches');
      expect(response.name, 'Branches');
      expect(response.icon, 'fa-solid fa-store');
      expect(response.value, 2);
    });

    test('tolerates a missing/null icon', () {
      final response = ProviderStatisticResponse.fromJson({
        'key': 'branches',
        'name': 'Branches',
        'value': 2,
      });

      expect(response.icon, isNull);
    });

    test('coerces a numeric value that arrives as a double', () {
      final response = ProviderStatisticResponse.fromJson({
        'key': 'branches',
        'name': 'Branches',
        'value': 2.0,
      });

      expect(response.value, 2);
    });

    test('maps to the domain entity 1:1', () {
      final response = ProviderStatisticResponse.fromJson({
        'key': 'workers',
        'name': 'Team Members',
        'icon': 'fa-solid fa-users',
        'value': 4,
      });

      expect(
        response.toEntity(),
        const ProviderStatisticEntity(
          key: 'workers',
          name: 'Team Members',
          icon: 'fa-solid fa-users',
          value: 4,
        ),
      );
    });
  });

  group('ProviderStatisticsResponse.fromJson', () {
    test('parses the statistics array', () {
      final response = ProviderStatisticsResponse.fromJson({
        'statistics': [
          {
            'key': 'branches',
            'name': 'Branches',
            'icon': 'fa-solid fa-store',
            'value': 2,
          },
          {
            'key': 'workers',
            'name': 'Team Members',
            'icon': 'fa-solid fa-users',
            'value': 4,
          },
        ],
      });

      expect(response.statistics, hasLength(2));
      expect(
        response.toEntity(),
        const [
          ProviderStatisticEntity(
            key: 'branches',
            name: 'Branches',
            icon: 'fa-solid fa-store',
            value: 2,
          ),
          ProviderStatisticEntity(
            key: 'workers',
            name: 'Team Members',
            icon: 'fa-solid fa-users',
            value: 4,
          ),
        ],
      );
    });

    test('parses an empty statistics array (caller has no permissions)', () {
      final response = ProviderStatisticsResponse.fromJson({
        'statistics': <dynamic>[],
      });

      expect(response.statistics, isEmpty);
      expect(response.toEntity(), isEmpty);
    });
  });
}
