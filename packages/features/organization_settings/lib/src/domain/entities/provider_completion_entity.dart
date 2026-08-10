import 'package:equatable/equatable.dart';

/// Stable, never-localized identifier for a completion checklist item —
/// `ProviderCompletionItemId`. Safe to switch on for icon/ordering logic;
/// never branch on [ProviderCompletionItemEntity.label] instead, it is
/// localized free text.
enum ProviderCompletionItemId {
  category,
  phone,
  email,
  workingHours,
  branches,
  team,
  services,
}

/// One row of `GET service-provider/completion` — `ProviderCompletionItemDto`.
class ProviderCompletionItemEntity extends Equatable {
  const ProviderCompletionItemEntity({
    required this.id,
    required this.label,
    required this.completed,
    required this.required,
  });

  /// Stable machine-readable id — never localized.
  final ProviderCompletionItemId id;

  /// Already-localized human text from the request's `Accept-Language`.
  final String label;
  final bool completed;
  final bool required;

  @override
  List<Object?> get props => [id, label, completed, required];
}

/// `GET service-provider/completion` response —
/// `ProviderCompletionResponseDto`.
///
/// [items] is already in the backend's stable render order (category, phone,
/// email, workingHours, then branches, team, services for an organization) —
/// never re-sort or re-derive it locally.
class ProviderCompletionEntity extends Equatable {
  const ProviderCompletionEntity({
    required this.percentage,
    required this.requiredCompleted,
    required this.requiredTotal,
    required this.visibleToCustomers,
    required this.items,
  });

  /// 0-100.
  final double percentage;
  final int requiredCompleted;
  final int requiredTotal;

  /// `true` only when every required step is complete.
  final bool visibleToCustomers;
  final List<ProviderCompletionItemEntity> items;

  @override
  List<Object?> get props => [
    percentage,
    requiredCompleted,
    requiredTotal,
    visibleToCustomers,
    items,
  ];
}
