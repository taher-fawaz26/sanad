import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';

ProviderCompletionItemId _itemIdFromJson(String value) => switch (value) {
  'category' => ProviderCompletionItemId.category,
  'phone' => ProviderCompletionItemId.phone,
  'email' => ProviderCompletionItemId.email,
  'workingHours' => ProviderCompletionItemId.workingHours,
  'branches' => ProviderCompletionItemId.branches,
  'team' => ProviderCompletionItemId.team,
  'services' => ProviderCompletionItemId.services,
  _ => throw ArgumentError.value(
    value,
    'value',
    'Unknown ProviderCompletionItemId',
  ),
};

/// Mirrors `ProviderCompletionItemDto` exactly.
class ProviderCompletionItemResponse {
  const ProviderCompletionItemResponse({
    required this.id,
    required this.label,
    required this.completed,
    required this.required,
  });

  factory ProviderCompletionItemResponse.fromJson(Map<String, dynamic> json) =>
      ProviderCompletionItemResponse(
        id: _itemIdFromJson(json['id'] as String),
        label: json['label'] as String,
        completed: json['completed'] as bool,
        required: json['required'] as bool,
      );

  final ProviderCompletionItemId id;
  final String label;
  final bool completed;
  final bool required;

  ProviderCompletionItemEntity toEntity() => ProviderCompletionItemEntity(
    id: id,
    label: label,
    completed: completed,
    required: required,
  );
}

/// Mirrors `ProviderCompletionResponseDto` exactly —
/// `GET service-provider/completion`.
class ProviderCompletionResponse {
  const ProviderCompletionResponse({
    required this.percentage,
    required this.requiredCompleted,
    required this.requiredTotal,
    required this.visibleToCustomers,
    required this.items,
  });

  factory ProviderCompletionResponse.fromJson(Map<String, dynamic> json) =>
      ProviderCompletionResponse(
        percentage: (json['percentage'] as num).toDouble(),
        requiredCompleted: json['requiredCompleted'] as int,
        requiredTotal: json['requiredTotal'] as int,
        visibleToCustomers: json['visibleToCustomers'] as bool,
        items: (json['items'] as List<dynamic>)
            .map(
              (item) => ProviderCompletionItemResponse.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  final double percentage;
  final int requiredCompleted;
  final int requiredTotal;
  final bool visibleToCustomers;
  final List<ProviderCompletionItemResponse> items;

  ProviderCompletionEntity toEntity() => ProviderCompletionEntity(
    percentage: percentage,
    requiredCompleted: requiredCompleted,
    requiredTotal: requiredTotal,
    visibleToCustomers: visibleToCustomers,
    items: items.map((item) => item.toEntity()).toList(),
  );
}
