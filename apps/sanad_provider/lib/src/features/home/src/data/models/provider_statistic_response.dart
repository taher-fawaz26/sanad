import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';

/// Mirrors a single entry of `GET service-provider/statistics`'s
/// `statistics` array.
class ProviderStatisticResponse {
  const ProviderStatisticResponse({
    required this.key,
    required this.name,
    required this.value,
    this.icon,
  });

  factory ProviderStatisticResponse.fromJson(Map<String, dynamic> json) =>
      ProviderStatisticResponse(
        key: json['key'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
        value: (json['value'] as num).toInt(),
      );

  final String key;
  final String name;
  final String? icon;
  final int value;

  ProviderStatisticEntity toEntity() => ProviderStatisticEntity(
    key: key,
    name: name,
    icon: icon,
    value: value,
  );
}

/// `GET service-provider/statistics` response — a caller-scoped list of
/// dashboard statistic cards.
class ProviderStatisticsResponse {
  const ProviderStatisticsResponse({required this.statistics});

  factory ProviderStatisticsResponse.fromJson(Map<String, dynamic> json) =>
      ProviderStatisticsResponse(
        statistics: (json['statistics'] as List)
            .map(
              (item) =>
                  ProviderStatisticResponse.fromJson(
                    item as Map<String, dynamic>,
                  ),
            )
            .toList(),
      );

  final List<ProviderStatisticResponse> statistics;

  List<ProviderStatisticEntity> toEntity() =>
      statistics.map((item) => item.toEntity()).toList();
}
